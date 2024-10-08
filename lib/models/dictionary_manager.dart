import 'dart:async';
import 'dart:io';
import 'dart:core';
import 'dart:math';
import 'dart:convert';
import 'package:dikt/common/helpers.dart';
import 'package:dikt/common/isolate_pool.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:ikvpack/ikvpack.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'indexed_dictionary.dart';
import '../common/file_stream.dart';

String nameToIkvPath(String name) {
  var fileName = 'dik_${name.replaceAll(' ', '_').toLowerCase()}';

  if (fileName.length > 127) {
    fileName = fileName.substring(0, min(127, fileName.length));
  }

  return '${DictionaryManager.homePath}/$fileName.dikt';
}

class BundledBinaryDictionary {
  final String assetFileName;
  final String name;
  final String hash;

  const BundledBinaryDictionary(this.assetFileName, this.name, this.hash);
  String get ikvPath {
    return nameToIkvPath(name);
  }
}

const bundledBinaryDictionaries = [
  BundledBinaryDictionary(
      'assets/dictionaries/dik_enenwordnet3.dikt', 'EN_EN WordNet 3', '4')
];

enum DictionaryBeingProcessedState {
  pending,
  inprogress,
  success,
  error,
  skipped
}

class DictionaryBeingProcessed {
  final String name;
  final BundledBinaryDictionary? bundledBinaryDictionary;
  final IndexedDictionary? indexedDictionary;
  final PlatformFile? file;

  DictionaryBeingProcessed.bundledBinary(
      BundledBinaryDictionary this.bundledBinaryDictionary)
      : name = bundledBinaryDictionary.name,
        file = null,
        indexedDictionary = null;

  DictionaryBeingProcessed.indexed(IndexedDictionary this.indexedDictionary)
      : name = indexedDictionary.name,
        file = null,
        bundledBinaryDictionary = null;

  DictionaryBeingProcessed.file(PlatformFile this.file)
      : name = (file.path ?? file.name)
            .split('/')
            .last
            .split('\\')
            .last
            .replaceFirst('.json', '')
            .replaceFirst('.dikt', '')
            .replaceFirst('.mdikt', ''),
        indexedDictionary = null,
        bundledBinaryDictionary = null;

  DictionaryBeingProcessedState _state = DictionaryBeingProcessedState.pending;

  DictionaryBeingProcessedState get state {
    return _state;
  }

  set state(DictionaryBeingProcessedState value) {
    if (value != _state) {
      _state = value;
    }
  }

  int? _progressPercent;

  int? get progressPercent {
    return _progressPercent;
  }

  set progressPercent(int? value) {
    if (_progressPercent != value) {
      _progressPercent = value;
    }
  }
}

enum ManagerCurrentOperation { preparing, indexing, loading, idle }

class DictionaryManager extends ChangeNotifier with Debounce {
  static const dictionairesBoxName = 'dictionairesboxname';
  static late Box<IndexedDictionary> _dictionaries;
  static late String homePath;
  static String? testPath;

  static bool hiveDicsDeleted = false;

  static Future<void> init([String? filesFolder]) async {
    if (filesFolder == null) {
      homePath =
          kIsWeb ? '/webhome' : (await getApplicationDocumentsDirectory()).path;
      if (!kIsWeb && Platform.isWindows) {
        homePath += '\\dikt';
      } else if (!kIsWeb && Platform.isLinux) {
        homePath += '/dikt';
      }
      Hive.init(homePath);
      try {
        var oldHive = Directory(homePath)
            .listSync(recursive: false, followLinks: false)
            .where((f) =>
                f.path.endsWith('.hive') &&
                !f.path.contains(dictionairesBoxName) &&
                !f.path.contains('.lock'))
            .toList();
        if (oldHive.isNotEmpty) {
          for (var f in oldHive) {
            f.deleteSync();
          }
        }
      } catch (_) {}
    } else {
      Hive.init(filesFolder); // autotests
      homePath = filesFolder;
      DictionaryManager.testPath = filesFolder;
    }
    Hive.registerAdapter(IndexedDictionaryAdapter(), override: true);
    _dictionaries = await Hive.openBox(dictionairesBoxName);
  }

  Completer<void>? _partiallyLoaded;

  Future<void>? get partiallyLoaded {
    return _partiallyLoaded?.future;
  }

  Future<void> indexAndLoadDictionaries([bool skipBundled = false]) async {
    _isRunning = true;
    _canceled = false;
    _partiallyLoaded = Completer();

    if (!skipBundled) {
      _currentOperation = ManagerCurrentOperation.preparing;
      await _checkAndIndexBundledDictionaries();

      _initDictionaryCollections();
    }

    await _cleanupJunkDictionaries();

    _currentOperation = ManagerCurrentOperation.loading;
    await _loadEnabledDictionaries();

    _initDictionaryCollections();

    _isRunning = false;
  }

  // Workaround for testing, avoid disposing object between tests
  @override
  void dispose() {
    if (testPath == null) super.dispose();
  }

  void _initDictionaryCollections() {
    _dictionariesAllList = <IndexedDictionary>[];

    for (var i = 0; i < _dictionaries.length; i++) {
      var d = _dictionaries.getAt(i)!;
      _dictionariesAllList.add(d);
    }

    _sortAllDictionariesByOrder();

    _dictionariesReadyList = <IndexedDictionary>[];
    for (var d in _dictionariesAllList) {
      if (d.isReadyToUse) _dictionariesReadyList.add(d);
    }

    _dictionariesEnabledList = <IndexedDictionary>[];
    for (var i = 0; i < _dictionariesReadyList.length; i++) {
      var d = _dictionariesReadyList[i];
      if (d.isEnabled && !d.isError) _dictionariesEnabledList.add(d);
    }

    _ikvPacksLoaded = dictionariesLoaded
        .map<List<IkvPack>>((d) => d.ikvs)
        .fold<List<IkvPack>>([], (previousValue, element) {
      previousValue.addAll(element);
      return previousValue;
    });
  }

  int get totalDictionaries => _dictionariesAllList.length;

  void _sortAllDictionariesByOrder() {
    _dictionariesAllList.sort((a, b) {
      return a.order - b.order;
    });
    var i = 0;
    for (var d in _dictionariesAllList) {
      d.order = i;
      i++;
      d.save();
    }
  }

  // E.g. a user reloads pages while indexing file, there's not-ready dictioanry left
  Future _cleanupJunkDictionaries() async {
    try {
      var indexesToDelete = <int>[];
      for (var i = 0; i < _dictionaries.length; i++) {
        var d = _dictionaries.getAt(i)!;
        if (!d.isBundled && !d.isReadyToUse) {
          IkvPack.delete(d.ikvPath);
          indexesToDelete.add(i);
        }
      }

      for (var i in indexesToDelete) {
        _dictionaries.deleteAt(i);
      }
    } catch (e) {
      debugPrint('Error cleaning junk dictionaries\n$e');
    }
  }

  Future _loadEnabledDictionaries() async {
    _dictionariesBeingProcessed = [];

    for (var i = 0; i < _dictionaries.length; i++) {
      var d = _dictionaries.getAt(i)!;
      if (d.isReadyToUse && d.isEnabled) {
        _dictionariesBeingProcessed
            .add(DictionaryBeingProcessed.indexed(_dictionaries.getAt(i)!));
      }
    }

    if (_dictionariesBeingProcessed.isNotEmpty) {
      notifyListeners();
      List<Future<List<IkvPack>>> futures = [];

      if (!kIsWeb) await pool!.started; // JIC wait for pool to finish startup

      for (var i in _dictionariesBeingProcessed) {
        //TDO, remove delay, used for debuging
        //await Future.delayed(const Duration(seconds: 3));
        i.state = DictionaryBeingProcessedState.inprogress;
        notifyListeners();

        var f = i.indexedDictionary!.openIkvs(pool);

        f.then((value) {
          i.state = DictionaryBeingProcessedState.success;
          _initDictionaryCollections();
          if (!_partiallyLoaded!.isCompleted) _partiallyLoaded!.complete();
          notifyListeners();
        }).catchError((err) {
          debugPrint(
              "Error loading IkvPack: ${i.indexedDictionary!.ikvPath}\n$err");

          i.state = DictionaryBeingProcessedState.error;
          i.indexedDictionary!.isError = true;
          notifyListeners();
        });
        futures.add(f);
      }
      try {
        await Future.wait(futures);
        //pool?.stop();
      } catch (e) {
        //pool?.stop();
      }
    }
  }

  int _indexFromIkvPath(String? ikvPath, [bool throwIfNotFound = true]) {
    for (var i = 0; i < _dictionaries.length; i++) {
      var d = _dictionaries.getAt(i);
      if (d != null && d.ikvPath == ikvPath) return i;
    }

    if (throwIfNotFound) {
      throw 'Dictionary with path $ikvPath not found in Hive DB';
    }

    return -1;
  }

  Future reindexBundledDictionaries(String? ikvPath) async {
    var i = _indexFromIkvPath(ikvPath);
    _dictionaries.deleteAt(i);
    indexAndLoadDictionaries();
  }

  Future _checkAndIndexBundledDictionaries() async {
    _dictionariesBeingProcessed = <DictionaryBeingProcessed>[];

    for (var i in bundledBinaryDictionaries) {
      if (_indexFromIkvPath(i.ikvPath, false) == -1) {
        _dictionariesBeingProcessed
            .add(DictionaryBeingProcessed.bundledBinary(i));
      } else {
        _dictionaries.getAt(_indexFromIkvPath(i.ikvPath))!.isBundled = true;
      }
    }

    if (_dictionariesBeingProcessed.isNotEmpty) {
      _currentOperation = ManagerCurrentOperation.indexing;
      await _indexBundledDictionaries(_dictionariesBeingProcessed);
    }
  }

  Future<void> _indexBundledDictionaries(
      List<DictionaryBeingProcessed> bds) async {
    Indexer getIndexer(
        DictionaryBeingProcessed dictionaryProcessed, String? ikvPath) {
      var bbd = dictionaryProcessed.bundledBinaryDictionary!;
      return BundledIndexer(bbd.assetFileName, ikvPath, (progress) {
        dictionaryProcessed.progressPercent = progress;
        notifyListeners();
      });
    }

    debugPrint('Extracing bundled dictionaries: ${DateTime.now()}');
    await _runIndexer(bds, getIndexer);
  }

  Indexer? _curIndexer;

  Future _runIndexer(
      List<DictionaryBeingProcessed> dictionariesProcessed,
      Indexer Function(
              DictionaryBeingProcessed dictionaryProcessed, String? ikvPath)
          getIndexer,
      {int startOrderAt = 0,
      Completer? finished}) async {
    for (var i = 0; i < dictionariesProcessed.length; i++) {
      if (_canceled) break;
      var d = IndexedDictionary();
      d.isBundled = dictionariesProcessed[i].bundledBinaryDictionary != null;
      if (dictionariesProcessed[i].bundledBinaryDictionary != null) {
        d.hash = dictionariesProcessed[i].bundledBinaryDictionary!.hash;
      }
      d.name = dictionariesProcessed[i].name;

      // Check if the dictionary name already exists in the list of dictionaries being processed
      bool doesDictionaryExist =
          _dictionariesAllList.any((dictionary) => dictionary.name == d.name);

      if (doesDictionaryExist) {
        // If the dictionary already exists, set its state to skipped and continue to the next iteration
        dictionariesProcessed[i].state = DictionaryBeingProcessedState.skipped;
        if (i == dictionariesProcessed.length - 1 && finished != null) {
          finished.complete();
        }
        continue;
      }

      debugPrint('  /Dictionary: ${d.name}');

      dictionariesProcessed[i].state = DictionaryBeingProcessedState.inprogress;
      notifyListeners();

      d.ikvPath = nameToIkvPath(d.name);
      d.isEnabled = true;
      d.isReadyToUse = false;
      d.order = startOrderAt + i;

      _dictionaries.add(d);
      _curIndexer = getIndexer(dictionariesProcessed[i], d.ikvPath);
      try {
        var ikvs = await _curIndexer!.run();
        if (ikvs.length > 1) {
          d.ikvPath = d.ikvPath.substring(0, d.ikvPath.length - 5);
          d.ikvPath = '${d.ikvPath}.part${ikvs.length}.dikt';
        }

        if (!_curIndexer!.canceled) {
          d.isReadyToUse = true;
          if (!d.isBundled) {
            d.isLoaded = true;
          }
          d.ikvs = ikvs;
          d.save();
        } else if (!d.isBundled) {
          debugPrint("Canceling box indexing: ${d.ikvPath}");
          d.delete();
          IkvPack.delete(d.ikvPath);
        }
        dictionariesProcessed[i].state = DictionaryBeingProcessedState.success;
        notifyListeners();
        if (i == dictionariesProcessed.length - 1 && finished != null) {
          finished.complete();
        }
      } catch (err) {
        d.isError = true;

        if (!d.isBundled) {
          var ikvPath = d.ikvPath;
          d.delete();
          var i = _indexFromIkvPath(ikvPath, false);
          if (i > -1) _dictionaries.delete(i);
        }

        debugPrint("Error indexing IkvPack: ${d.ikvPath}\n$err");
        dictionariesProcessed[i].state = DictionaryBeingProcessedState.error;
        notifyListeners();
        if (i == dictionariesProcessed.length - 1 && finished != null) {
          finished.completeError(err);
        }
      }
    }
  }

  Future<void> indexAndLoadJsonOrDiktFiles(List<PlatformFile> files) async {
    _isRunning = true;
    _canceled = false;
    _dictionariesBeingProcessed = [];
    var completer = Completer();

    _currentOperation = ManagerCurrentOperation.preparing;
    notifyListeners();

    debugPrint('Processing JSON/DIKT files: ${DateTime.now()}');

    for (var f in files) {
      _dictionariesBeingProcessed.add(DictionaryBeingProcessed.file(f));
    }

    _currentOperation = ManagerCurrentOperation.indexing;

    Indexer getIndexer(
        DictionaryBeingProcessed dictionaryProcessed, String? ikvPath) {
      void progress(progress) {
        dictionaryProcessed.progressPercent = progress;
        notifyListeners();
      }

      return dictionaryProcessed.file!.name.endsWith('.dikt') ||
              dictionaryProcessed.file!.name.endsWith('.mdikt')
          ? DiktFileIndexer(dictionaryProcessed.file, ikvPath, progress)
          : JsonFileIndexer(dictionaryProcessed.file, ikvPath, progress);
    }

    debugPrint(
        'Indexing JSON/DIKT files and packing to IkvPack: ${DateTime.now()}');
    await _runIndexer(_dictionariesBeingProcessed, getIndexer,
        startOrderAt: 0 - files.length,
        finished: completer); // put dictionaries at the top

    _initDictionaryCollections();

    _isRunning = false;

    notifyListeners();

    return completer.future;
  }

  bool _canceled = false;

  @override
  void cancel() {
    _curIndexer?.cancel();
    _canceled = true;
    _isRunning = false;
    notifyListeners();
  }

  List<IndexedDictionary> _dictionariesAllList = [];

  List<IndexedDictionary> get dictionariesAll {
    return _dictionariesAllList;
  }

  List<IndexedDictionary> _dictionariesReadyList = [];

  List<IndexedDictionary> get dictionariesReady {
    return _dictionariesReadyList;
  }

  List<IndexedDictionary> _dictionariesEnabledList = [];

  List<IndexedDictionary> get dictionariesEnabled {
    return _dictionariesEnabledList;
  }

  List<IndexedDictionary> get dictionariesLoaded =>
      _dictionariesEnabledList.where((e) => e.isLoaded).toList();

  Iterable<IkvPack> _ikvPacksLoaded = [];
  Iterable<IkvPack> get ikvPacksLoaded => _ikvPacksLoaded;

  void reorder(int oldIndex, int newIndex) {
    for (var i = 0; i < _dictionariesReadyList.length; i++) {
      if (newIndex < oldIndex) {
        if (i < newIndex) {
          _dictionariesReadyList[i].order--;
        } else {
          _dictionariesReadyList[i].order++;
        }
      } else {
        if (i <= newIndex) {
          _dictionariesReadyList[i].order--;
        } else {
          _dictionariesReadyList[i].order++;
        }
      }
    }

    _dictionariesReadyList[oldIndex].order = newIndex;

    _initDictionaryCollections();

    notifyListeners();
  }

  void switchIsEnabled(IndexedDictionary dictionary) {
    dictionary.isEnabled = !dictionary.isEnabled;
    dictionary.save();
    _initDictionaryCollections();
    notifyListeners();
  }

  void deleteDictionary(String? ikvPath) {
    var d = _dictionariesAllList.where((d) => d.ikvPath == ikvPath).first;
    try {
      // this method can throw if the path doesn't exist
      // path can be unexisting if dictionary happens to be errored
      // silence the error
      if (!d.isMultiPart) {
        IkvPack.delete(d.ikvPath);
      } else {
        for (var p in IndexedDictionary.getPartsPaths(d.ikvPath)) {
          IkvPack.delete(p);
        }
      }
    } catch (e) {
      debugPrint('Error while deleting dictionary $ikvPath, $e');
    }
    if (bundledBinaryDictionaries.any((e) => e.ikvPath == d.ikvPath)) {
      d.isReadyToUse = false;
      d.save();
    } else {
      d.delete();
    }
    _initDictionaryCollections();
    notifyListeners();
  }

  List<DictionaryBeingProcessed> _dictionariesBeingProcessed = [];

  List<DictionaryBeingProcessed> get dictionariesBeingProcessed {
    return _dictionariesBeingProcessed;
  }

  IndexedDictionary? getByHash(String hash) {
    var d = _dictionariesReadyList.where((e) => e.hash == hash);
    if (d.isNotEmpty) return d.first;
    return null;
  }

  bool exisitsByHash(String hash) {
    var d = _dictionariesReadyList.where((e) => e.hash == hash);
    return d.isNotEmpty;
  }

  bool __isRunning = false;

  bool get isRunning {
    return __isRunning;
  }

  set _isRunning(bool value) {
    if (value != __isRunning) {
      __isRunning = value;
      if (!__isRunning) _currentOperation = ManagerCurrentOperation.idle;
      notifyListeners();
    }
  }

  bool _gettingFileList = false;

  /// File picker might be slow returning back the list of files
  /// (noticable on Android). Use this property to allow show spinner
  bool get gettingFileList => _gettingFileList;

  /// Debounced
  set gettingFileList(bool v) {
    if (v != _gettingFileList) {
      if (v) {
        debounce(() {
          _gettingFileList = v;
          notifyListeners();
        }, 700);
      } else {
        cancel();
        _gettingFileList = false;
        notifyListeners();
      }
    }
  }

  ManagerCurrentOperation __currentOperation =
      ManagerCurrentOperation.preparing;

  ManagerCurrentOperation get currentOperation {
    return __currentOperation;
  }

  set _currentOperation(ManagerCurrentOperation value) {
    if (value != __currentOperation) {
      __currentOperation = value;
      notifyListeners();
    }
  }

  // used in debug manually to get sense of dictionary stats
  // ignore: unused_element
  void _getKeyStats() {
    var sw = Stopwatch();

    sw.start();

    var keysCount = 0;

    for (var d in dictionariesLoaded) {
      keysCount += d.ikvs.fold(0, (prev, curr) => prev + curr.length);
    }
    sw.stop();
    debugPrint('Non-Unique keys $keysCount [${sw.elapsedMilliseconds}ms]');

    List<String?> keys = [];

    sw.reset();
    sw.start();

    var bytes = 0;
    var totalLength = 0;

    for (var d in dictionariesLoaded) {
      for (var i in d.ikvs) {
        for (var k in i.keys) {
          for (var c in k.codeUnits) {
            bytes += ((c.bitLength + 1) / 8).ceil();
          }
          totalLength += k.length;
        }
      }
    }
    sw.stop();

    debugPrint(
        'Size in bytes of non-unique keys $bytes, total characters $totalLength, bytes/char ${(bytes / totalLength).toStringAsFixed(2)} [${sw.elapsedMilliseconds}ms]');

    sw.start();
    sw.reset();

    for (var d in dictionariesLoaded) {
      for (var i in d.ikvs) {
        for (var k in i.keys) {
          keys.add(k);
        }
      }
    }
    keys.sort();
    var key = keys[0];
    for (var i = 1; i < keys.length; i++) {
      if (keys[i] == key) {
        keys[i] = null;
      } else {
        key = keys[i];
      }
    }

    keys = keys.where((k) => k != null).toList();

    sw.stop();
    debugPrint('Unique keys ${keys.length} [${sw.elapsedMilliseconds}ms]');

    sw.reset();
    sw.start();

    bytes = 0;
    totalLength = 0;

    for (var k in keys) {
      for (var c in k!.codeUnits) {
        bytes += ((c.bitLength + 1) / 8).ceil();
      }
      totalLength += k.length;
    }
    sw.stop();

    debugPrint(
        'Size in bytes of unique keys $bytes, total characters $totalLength, bytes/char ${(bytes / totalLength).toStringAsFixed(2)} [${sw.elapsedMilliseconds}ms]');
  }
}

class IsolateParams {
  const IsolateParams(this.assetValue, this.file);
  final String assetValue;
  final int file;
}

abstract class Indexer {
  Future<List<IkvPack>> run();

  bool _canceled = false;

  bool get canceled {
    return _canceled;
  }

  void cancel() {
    _canceled = true;
  }

  void _deleteFiles(Iterable<String> paths) {
    try {
      for (var p in paths) {
        File(p).delete();
      }
    } catch (e) {
      debugPrint('DiktFileIndexer, error deleting files\n $e');
    }
  }
}

class DiktFileIndexer extends Indexer {
  final PlatformFile? file;
  final Completer<List<IkvPack>> runCompleter = Completer<List<IkvPack>>();
  final String? ikvPath;
  final Function(int progressPercent) updateProgress;

  DiktFileIndexer(this.file, this.ikvPath, this.updateProgress);

  Future<bool>? _awaitableUpdateProgeress(int progress) {
    if (_canceled) return null;
    return Future(() {
      updateProgress(progress);
      return false;
    });
  }

  // TODO test cleanup of file when dictionary indexing faling midway
  @override
  Future<List<IkvPack>> run() async {
    var sourceFilePath = file!.path ?? file!.name;
    var multipart = sourceFilePath.toLowerCase().endsWith('.mdikt');
    debugPrint('$sourceFilePath\n');

    var sw = Stopwatch();

    debugPrint(
        'Saving DIKT binary dictionary (${multipart ? 'multi-part' : 'single-part'}): $sourceFilePath');
    sw.start();
    updateProgress(3);
    if (_canceled) {
      runCompleter.complete(<IkvPack>[]);
      return runCompleter.future;
    }

    var cleanupPaths = <String>[];

    try {
      if (!kIsWeb && pool != null) {
        var sourceData = File(sourceFilePath).readAsBytesSync();
        //TODO, test delete file if canceled
        updateProgress(5);
        if (!multipart) {
          await File(ikvPath!).writeAsBytes(sourceData);
          cleanupPaths.add(ikvPath!);
          if (_canceled) {
            runCompleter.complete(<IkvPack>[]);
            _deleteFiles([ikvPath!]);
            return runCompleter.future;
          }
          updateProgress(20);
          var ikv =
              await IkvPackProxy.loadInIsolatePoolAndUseProxy(pool!, ikvPath!);
          if (_canceled) {
            runCompleter.complete(<IkvPack>[]);
            _deleteFiles([ikvPath!]);
            return runCompleter.future;
          }
          updateProgress(100);

          runCompleter.complete([ikv]);
        } else {
          var outputDir = path.dirname(ikvPath!);
          var count = await extractFromSingleFilePooled(
              sourceFilePath, outputDir, pool!, '.dikt', ikvPath!);
          var partsPaths =
              IndexedDictionary.getPartsPathsFromOneFile(ikvPath!, count);
          cleanupPaths = partsPaths;

          if (_canceled) {
            runCompleter.complete(<IkvPack>[]);
            _deleteFiles([ikvPath!]);
            return runCompleter.future;
          }
          updateProgress(25);
          var ikvs = <IkvPack>[];

          for (var p in partsPaths) {
            ikvs.add(await IkvPackProxy.loadInIsolatePoolAndUseProxy(pool!, p));
          }
          if (_canceled) {
            runCompleter.complete(<IkvPack>[]);
            _deleteFiles([ikvPath!]);
            return runCompleter.future;
          }
          updateProgress(100);

          runCompleter.complete(ikvs);
        }
      } else {
        if (!multipart) {
          var ikv = await IkvPack.buildFromBytesAsync(
              file!.bytes!.buffer.asByteData(), true, (progress) async {
            return _awaitableUpdateProgeress(3 + (progress * 0.12).round());
          });
          updateProgress(15);
          if (_canceled) {
            runCompleter.complete(<IkvPack>[]);
            return runCompleter.future;
          }
          await ikv!.saveTo(ikvPath!,
              (progress) => updateProgress(15 + (progress * 0.85).round()));
          runCompleter.complete([ikv]);
        } else {
          throw 'Multipart DIKT files are not supported in Web and non isolate pool modes';
        }
      }

      debugPrint('Indexing done(ms): ${sw.elapsedMilliseconds}');
    } catch (err) {
      _deleteFiles(cleanupPaths);
      runCompleter.completeError(err);
    }

    return runCompleter.future;
  }
}

class JsonFileIndexer extends Indexer {
  final PlatformFile? file;
  final Completer<List<IkvPack>> runCompleter = Completer<List<IkvPack>>();
  final String? ikvPath;
  final Function(int progressPercent) updateProgress;

  JsonFileIndexer(this.file, this.ikvPath, this.updateProgress);

  @override
  Future<List<IkvPack>> run() async {
    return kIsWeb ? _runWeb() : _runVm();
  }

  Future<bool>? _awaitableUpdateProgeress(int progress) {
    if (_canceled) return null;
    return Future(() {
      updateProgress(progress);
      return false;
    });
  }

  // TODO, add cleanup of canceled/errored dictionaries, remove data from Indexed DB
  Future<List<IkvPack>> _runWeb() async {
    debugPrint(file!.path ?? '${file!.name}\n');
    // Chunked json decoding isn't available in web
    // var inSink = converterJson.startChunkedConversion(outSink);

    var sw = Stopwatch();
    sw.start();

    try {
      if (_canceled) {
        runCompleter.complete([]);
        return runCompleter.future;
      }

      var s = '';
      updateProgress(3);
      // Let UI pick up the update from microtask que
      await Future(() {
        s = utf8.decode(file!.bytes!);
        debugPrint('JSON read (ms): ${sw.elapsedMilliseconds}');
      });

      if (_canceled) {
        runCompleter.complete([]);
        return runCompleter.future;
      }

      updateProgress(5);

      var m = <String, String>{};
      await Future(() {
        Map mm = json.decode(s);
        m = mm.cast<String, String>();
        debugPrint('JSON decoded (ms): ${sw.elapsedMilliseconds}');
      });

      var ikv = await IkvPack.buildFromMapAsync(m, true, (progress) async {
        return _awaitableUpdateProgeress(5 + (progress * 0.25).round());
      });

      if (_canceled) {
        runCompleter.complete([]);
        return runCompleter.future;
      }

      updateProgress(30);
      if (_canceled) {
        runCompleter.complete([]);
        return runCompleter.future;
      }

      await ikv!.saveTo(ikvPath!,
          (progress) => updateProgress(30 + (progress * 0.65).round()));

      updateProgress(95);
      if (_canceled) {
        runCompleter.complete([]);
        return runCompleter.future;
      }

      ikv = await IkvPack.load(ikvPath!);
      updateProgress(100);

      debugPrint('Indexing done(ms): ${sw.elapsedMilliseconds}');
      runCompleter.complete([ikv]);
    } catch (err) {
      _canceled = true;
      runCompleter.completeError(err);
    }

    return runCompleter.future;
  }

  Future<List<IkvPack>> _runVm() async {
    var path = this.file!.path ?? this.file!.name;
    debugPrint('$path\n');
    var file = File(path);
    var s = FileStream(path, null, null);
    var length = await file.length();

    var sw = Stopwatch();

    var converterJson = const JsonDecoder();

    // Dart doesn't support chunked JSON decoding, entire map of decoded values
    // comes in as a single chunk
    var outSinkJson = ChunkedConversionSink.withCallback((chunks) async {
      try {
        var result =
            (chunks.single! as Map<dynamic, dynamic>).cast<String, String>();
        var ikv = await IkvPack.buildFromMapInIsolate(result, true, (progress) {
          updateProgress(20 + (progress * 0.70).round());
        });
        await ikv.saveTo(ikvPath!);

        updateProgress(98);

        ikv = pool == null
            ? await IkvPack.load(ikvPath!)
            : await IkvPackProxy.loadInIsolatePoolAndUseProxy(pool!, ikvPath!);
        updateProgress(100);
        sw.stop();
        runCompleter.complete([ikv]);
        debugPrint('ELAPSED (ms): ${sw.elapsedMilliseconds}');
      } catch (err) {
        _canceled = true;
        _deleteFiles([ikvPath!]);
        runCompleter.completeError(err);
      }
    });

    sw.start();
    var inSinkZip = converterJson.startChunkedConversion(outSinkJson);

    var progress = -1;
    var utf = s.transform(utf8.decoder);
    StreamSubscription<String>? subscription;

    subscription = utf.listen((event) {
      try {
        if (_canceled) {
          subscription?.cancel();
          _deleteFiles([ikvPath!]);
          runCompleter.complete([]);
        }
        inSinkZip.add(event);
        var curr = (s.position / length * 20).round();
        if (curr != progress) {
          progress = curr;
          updateProgress(progress);
        }
      } catch (err) {
        _deleteFiles([ikvPath!]);
        runCompleter.completeError(err);
        _canceled = true;
      }
    }, onDone: () {
      try {
        inSinkZip.close();
      } catch (err) {
        _deleteFiles([ikvPath!]);
        runCompleter.completeError(err);
        _canceled = true;
      }
    });

    return runCompleter.future;
  }
}

class BundledIndexer extends Indexer {
  final String assetName;
  final Completer<List<IkvPack>> runCompleter = Completer<List<IkvPack>>();
  final String? fileName;
  final Function(int progressPercent) updateProgress;

  BundledIndexer(this.assetName, this.fileName, this.updateProgress);

  Future<bool>? _awaitableUpdateProgeress(int progress) {
    if (_canceled) return null;
    return Future(() {
      updateProgress(progress);
      return false;
    });
  }

  @override
  Future<List<IkvPack>> run() async {
    debugPrint('Indexing bundled bianry dictionary: $assetName');
    var sw = Stopwatch();
    sw.start();
    updateProgress(0);
    var asset = await rootBundle.load(assetName);
    updateProgress(5);
    if (_canceled) {
      runCompleter.complete([]);
      return runCompleter.future;
    }

    try {
      if (!kIsWeb) {
        File(fileName!).writeAsBytesSync(asset.buffer.asInt8List());
        runCompleter.complete([]);
      } else {
        // Cant just copy file in Web, parse asset and save via Ikv
        var ikv =
            await IkvPack.buildFromBytesAsync(asset, true, (progress) async {
          return _awaitableUpdateProgeress(5 + (progress * 0.1).round());
        });
        updateProgress(15);
        if (_canceled) {
          runCompleter.complete([]);
          return runCompleter.future;
        }
        await ikv!.saveTo(fileName!,
            (progress) => updateProgress(15 + (progress * 0.85).round()));
        updateProgress(100);
        runCompleter.complete([]);
      }

      debugPrint('Indexing done(ms): ${sw.elapsedMilliseconds}');
    } catch (err) {
      runCompleter.completeError(err);
    }
    return runCompleter.future;
  }
}
