import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:core';
import 'dart:math';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:ikvpack/ikvpack.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'indexedDictionary.dart';
import '../common/fileStream.dart';

String nameToIkvPath(String name) {
  var fileName = 'dik_' + name.replaceAll(' ', '_').toLowerCase();

  if (fileName.length > 127)
    fileName = fileName.substring(0, min(127, fileName.length));

  return DictionaryManager.homePath + '/' + fileName + 'ikv.dikt';
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
      'assets/dictionaries/dik_enenwordnet3.ikv.dikt', 'EN_EN WordNet 3', '4')
];

enum DictionaryBeingProcessedState { pending, inprogress, success, error }

class DictionaryBeingProcessed {
  final String name;
  final BundledBinaryDictionary bundledBinaryDictionary;
  final IndexedDictionary indexedDictionary;
  final PlatformFile file;

  DictionaryBeingProcessed.bundledBinary(this.bundledBinaryDictionary)
      : this.name = bundledBinaryDictionary.name,
        this.file = null,
        this.indexedDictionary = null;

  DictionaryBeingProcessed.indexed(this.indexedDictionary)
      : this.name = indexedDictionary.name,
        this.file = null,
        this.bundledBinaryDictionary = null;

  DictionaryBeingProcessed.file(this.file)
      : this.name = (file.path ?? file.name)
            .split('/')
            .last
            .split('\\')
            .last
            .replaceFirst('.json', '')
            .replaceFirst('.dikt', ''),
        this.indexedDictionary = null,
        this.bundledBinaryDictionary = null;

  DictionaryBeingProcessedState _state = DictionaryBeingProcessedState.pending;

  DictionaryBeingProcessedState get state {
    return _state;
  }

  set state(DictionaryBeingProcessedState value) {
    if (value != _state) {
      _state = value;
    }
  }

  int _progressPercent;

  int get progressPercent {
    return _progressPercent;
  }

  set progressPercent(int value) {
    if (_progressPercent != value) {
      _progressPercent = value;
    }
  }
}

enum ManagerCurrentOperation { preparing, indexing, loading, idle }

class DictionaryManager extends ChangeNotifier {
  static const dictionairesBoxName = 'dictionairesBoxName';
  static Box<IndexedDictionary> _dictionaries;
  static String homePath;

  static Future<void> init([String testPath]) async {
    if (testPath == null)
      await Hive.initFlutter();
    else
      Hive.init(testPath); // autotests
    Hive.registerAdapter(IndexedDictionaryAdapter());
    homePath = (await getApplicationDocumentsDirectory()).path;
    _dictionaries = await Hive.openBox(dictionairesBoxName);
  }

  Completer<void> _partiallyLoaded;

  Future<void> get partiallyLoaded {
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

    _currentOperation = ManagerCurrentOperation.loading;
    await _loadEnabledDictionaries();

    _initDictionaryCollections();

    _isRunning = false;
    //_getKeyStats();
  }

  void _initDictionaryCollections() {
    _dictionariesAllList = <IndexedDictionary>[];

    for (var i = 0; i < _dictionaries.length; i++) {
      var d = _dictionaries.getAt(i);
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
  }

  int get totalDictionaries => _dictionariesAllList.length;

  void _sortAllDictionariesByOrder() {
    _dictionariesAllList.sort((a, b) {
      if (a.order == null || b.order == null) return 0;
      return a.order - b.order;
    });
    var i = 0;
    for (var d in _dictionariesAllList) {
      d.order = i;
      i++;
      d.save();
    }
  }

  Future _loadEnabledDictionaries() async {
    _dictionariesBeingProcessed = [];

    for (var i in _dictionaries.keys) {
      var d = _dictionaries.get(i);
      if (d.isReadyToUse && d.isEnabled)
        _dictionariesBeingProcessed
            .add(DictionaryBeingProcessed.indexed(_dictionaries.get(i)));
    }

    if (_dictionariesBeingProcessed.length > 0) {
      notifyListeners();
      List<Future<IkvPack>> futures = [];

      List<Future<IkvPack>> futuresFour = [];
      int counter = 0;

      for (var i in _dictionariesBeingProcessed) {
        i.state = DictionaryBeingProcessedState.inprogress;
        notifyListeners();

        var f = i.indexedDictionary
            .openIkv(); //IkvPack.loadInIsolate(i.indexedDictionary.ikvPath);

        f.then((value) {
          i.state = DictionaryBeingProcessedState.success;
          //i.indexedDictionary.isLoaded = true;
          _initDictionaryCollections();
          if (!_partiallyLoaded.isCompleted) _partiallyLoaded.complete();
          notifyListeners();
        }).catchError((err) {
          print("Error loading box: " +
              i.indexedDictionary.ikvPath +
              "\n" +
              err.toString());

          i.state = DictionaryBeingProcessedState.error;
          i.indexedDictionary.isError = true;
          notifyListeners();
        });
        futures.add(f);
        counter++;
        if (counter > 5) futuresFour.add(f);
        if (futuresFour.length > 4) {
          await Future.wait(futuresFour);
          counter = 5;
          futuresFour.clear();
        }
      }
      try {
        await Future.wait(futures);
      } catch (e) {}
    }
  }

  Future reindexBundledDictionaries(String boxName) async {
    _dictionaries.delete(boxName);
    indexAndLoadDictionaries();
  }

  Future _checkAndIndexBundledDictionaries() async {
    _dictionariesBeingProcessed = <DictionaryBeingProcessed>[];

    for (var i in bundledBinaryDictionaries) {
      if (!_dictionaries.containsKey(i.ikvPath)) {
        _dictionariesBeingProcessed
            .add(DictionaryBeingProcessed.bundledBinary(i));
      } else {
        _dictionaries.get(i.ikvPath).isBundled = true;
      }
    }

    if (_dictionariesBeingProcessed.length > 0) {
      _currentOperation = ManagerCurrentOperation.indexing;
      await _indexBundledDictionaries(_dictionariesBeingProcessed);
    }
  }

  Future<void> _indexBundledDictionaries(
      List<DictionaryBeingProcessed> bds) async {
    Indexer getIndexer(
        DictionaryBeingProcessed dictionaryProcessed, String ikvPath) {
      var bbd = dictionaryProcessed.bundledBinaryDictionary;
      return BundledBinaryIndexer(bbd.assetFileName, ikvPath, (progress) {
        dictionaryProcessed.progressPercent = progress;
        notifyListeners();
      });
    }

    print('Loading bundled dictionaries to Hive DB: ' +
        DateTime.now().toString());
    await _runIndexer(bds, getIndexer);
  }

  Indexer _curIndexer;

  Future _runIndexer(
      List<DictionaryBeingProcessed> dictionariesProcessed,
      Indexer getIndexer(
          DictionaryBeingProcessed dictionaryProcessed, String ikvPath),
      {int startOrderAt = 0,
      Completer finished}) async {
    for (var i = 0; i < dictionariesProcessed.length; i++) {
      if (_canceled) break;
      var d = IndexedDictionary();
      d.isBundled = dictionariesProcessed[i].bundledBinaryDictionary != null;
      if (dictionariesProcessed[i].bundledBinaryDictionary != null) {
        d.hash = dictionariesProcessed[i].bundledBinaryDictionary.hash;
      }
      d.name = dictionariesProcessed[i].name;

      print('  /Dictionary: ' + d.name);

      dictionariesProcessed[i].state = DictionaryBeingProcessedState.inprogress;
      notifyListeners();

      d.ikvPath = nameToIkvPath(d.name);
      d.isEnabled = true;
      d.isReadyToUse = false;
      d.order = startOrderAt + i;

      _dictionaries.put(d.ikvPath, d);
      _curIndexer = getIndexer(dictionariesProcessed[i], d.ikvPath);
      try {
        await _curIndexer.run();

        if (!_curIndexer.canceled) {
          d.isReadyToUse = true;
          //d.isLoaded = true;

          d.save();
        } else if (!d.isBundled) {
          print("Canceling box indexing: " + d.ikvPath);
          d.delete();
          IkvPack.delete(d.ikvPath);
        }
        dictionariesProcessed[i].state = DictionaryBeingProcessedState.success;
        notifyListeners();
        if (i == dictionariesProcessed.length - 1 && finished != null)
          finished.complete();
      } catch (err) {
        d.isError = true;

        if (!d.isBundled) {
          var ikvPath = d.ikvPath;
          d.delete();
          _dictionaries.delete(ikvPath);
        }

        print("Error indexing box: " + d.ikvPath + "\n" + err.toString());
        dictionariesProcessed[i].state = DictionaryBeingProcessedState.error;
        notifyListeners();
        if (i == dictionariesProcessed.length - 1 && finished != null)
          finished.completeError(err);
      }
    }
  }

  Future<void> loadFromJsonOrDiktFiles(List<PlatformFile> files) async {
    _isRunning = true;
    _canceled = false;
    _dictionariesBeingProcessed = [];
    var completer = Completer();

    _currentOperation = ManagerCurrentOperation.preparing;
    notifyListeners();

    print('Processing JSON/DIKT files: ' + DateTime.now().toString());

    for (var f in files) {
      _dictionariesBeingProcessed.add(DictionaryBeingProcessed.file(f));
    }

    _currentOperation = ManagerCurrentOperation.indexing;

    Indexer getIndexer(
        DictionaryBeingProcessed dictionaryProcessed, String ikvPath) {
      var progress = (progress) {
        dictionaryProcessed.progressPercent = progress;
        notifyListeners();
      };

//TODO: add WebSupport for binary dictionary format
      return kIsWeb
          ? WebIndexer(dictionaryProcessed.file, ikvPath, progress)
          : dictionaryProcessed.file.name.endsWith('.dikt')
              ? DiktFileIndexer(dictionaryProcessed.file, ikvPath, progress)
              : JsonFileIndexer(dictionaryProcessed.file, ikvPath, progress);
    }

    print('Indexing JSON/DIKT files and loading to Hive DB: ' +
        DateTime.now().toString());
    await _runIndexer(_dictionariesBeingProcessed, getIndexer,
        startOrderAt: 0 - files.length,
        finished: completer); // put dictionaries at the top

    _initDictionaryCollections();

    _isRunning = false;

    notifyListeners();

    return completer.future;
  }

  bool _canceled = false;

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

  List<IndexedDictionary> get dictionariesLoaded {
    return _dictionariesEnabledList.where((e) => e.isLoaded).toList();
  }

  void reorder(int oldIndex, int newIndex) {
    for (var i = 0; i < _dictionariesReadyList.length; i++) {
      if (newIndex < oldIndex) {
        if (i < newIndex)
          _dictionariesReadyList[i].order--;
        else
          _dictionariesReadyList[i].order++;
      } else {
        if (i <= newIndex)
          _dictionariesReadyList[i].order--;
        else
          _dictionariesReadyList[i].order++;
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

  void deleteReadyDictionary(int index) {
    var d = _dictionariesReadyList[index];
    IkvPack.delete(d.ikvPath);
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

  IndexedDictionary getByHash(String hash) {
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
      keysCount += d.box.length;
    }
    sw.stop();
    print('Non-Unique keys ${keysCount} [${sw.elapsedMilliseconds}ms]');

    List<String> keys = [];

    sw.reset();
    sw.start();

    var bytes = 0;
    var totalLength = 0;

    for (var d in dictionariesLoaded) {
      for (var k in d.box.keys) {
        for (var c in k.codeUnits) {
          bytes += ((c.bitLength + 1) / 8).ceil();
        }
        totalLength += k.length;
      }
    }
    sw.stop();

    print(
        'Size in bytes of non-unique keys ${bytes}, total characters ${totalLength}, bytes/char ${(bytes / totalLength).toStringAsFixed(2)} [${sw.elapsedMilliseconds}ms]');

    sw.start();
    sw.reset();

    for (var d in dictionariesLoaded) {
      for (var k in d.box.keys) {
        keys.add(k);
      }
    }
    keys.sort();
    var key = keys[0];
    for (var i = 1; i < keys.length; i++)
      if (keys[i] == key) {
        keys[i] = null;
      } else {
        key = keys[i];
      }

    keys = keys.where((k) => k != null).toList();

    sw.stop();
    print('Unique keys ${keys.length} [${sw.elapsedMilliseconds}ms]');

    sw.reset();
    sw.start();

    bytes = 0;
    totalLength = 0;

    for (var k in keys) {
      for (var c in k.codeUnits) {
        bytes += ((c.bitLength + 1) / 8).ceil();
      }
      totalLength += k.length;
    }
    sw.stop();

    print(
        'Size in bytes of unique keys ${bytes}, total characters ${totalLength}, bytes/char ${(bytes / totalLength).toStringAsFixed(2)} [${sw.elapsedMilliseconds}ms]');
  }
}

class IsolateParams {
  const IsolateParams(this.assetValue, this.file);
  final String assetValue;
  final int file;
}

abstract class Indexer {
  Future<void> run() async {}

  bool _canceled = false;

  bool get canceled {
    return _canceled;
  }

  void cancel() {
    _canceled = true;
  }
}

class DiktFileIndexer extends Indexer {
  final PlatformFile file;
  final Completer<void> runCompleter = Completer<void>();
  final String ikvPath;
  final Function(int progressPercent) updateProgress;

  DiktFileIndexer(this.file, this.ikvPath, this.updateProgress);

  Future<void> run() async {
    var path = this.file.path ?? this.file.name;
    print(path + '\n');
    var sourceData = ByteData.sublistView(File(path).readAsBytesSync());

    var sw = Stopwatch();

    print('Indexing DIKT bianry dictionary: ' + path);
    sw.start();
    updateProgress(3);
    if (_canceled) {
      runCompleter.complete();
      return runCompleter.future;
    }

    try {
      if (!kIsWeb) {
        File(ikvPath).writeAsBytesSync(sourceData.buffer.asInt8List());
        var ikv = IkvPack(ikvPath); //try loadinb file
        ikv.dispose();

        runCompleter.complete();
      } else {
        //TODO
      }

      print('Indexing done(ms): ' + sw.elapsedMilliseconds.toString());
    } catch (err) {
      runCompleter.completeError(err);
    }

    return runCompleter.future;
  }
}

class JsonFileIndexer extends Indexer {
  final PlatformFile file;
  final Completer<void> runCompleter = Completer<void>();
  final String ikvPath;
  final Function(int progressPercent) updateProgress;

  JsonFileIndexer(this.file, this.ikvPath, this.updateProgress);

  Future<void> run() async {
    var path = this.file.path ?? this.file.name;
    print(path + '\n');
    var file = File(path);
    var s = FileStream(path, null, null);
    var length = await file.length();

    var sw = Stopwatch();

    var converterJson = JsonDecoder();

    // Dart doesn't support chunked JSON decoding, entire map of decoded values
    // comes in in a single chunk
    var outSinkJson = ChunkedConversionSink.withCallback((chunks) {
      try {
        var result = chunks.single.cast<String, String>();
        var ikv = IkvPack.fromMap(result);
        ikv.saveTo(ikvPath);
        sw.stop();
        runCompleter.complete();
        print('ELAPSED (ms): ' + sw.elapsedMilliseconds.toString());
      } catch (err) {
        _canceled = true;
        runCompleter.completeError(err);
      }
    });

    sw.start();
    var inSinkZip = converterJson.startChunkedConversion(outSinkJson);

    var progress = -1;
    var utf = s.transform(utf8.decoder);
    StreamSubscription<String> subscription;

    subscription = utf.listen((event) {
      try {
        if (_canceled) {
          subscription?.cancel();
          runCompleter.complete();
        }
        inSinkZip.add(event);
        var curr = (s.position / length * 100).round();
        if (curr != progress) {
          progress = curr;
          updateProgress(progress);
        }
      } catch (err) {
        runCompleter.completeError(err);
        _canceled = true;
      }
    }, onDone: () => inSinkZip.close());

    return runCompleter.future;
  }
}

class WebIndexer extends Indexer {
  final PlatformFile file;
  final Completer<void> runCompleter = Completer<void>();
  final String ikvPath;
  final Function(int progressPercent) updateProgress;

  WebIndexer(this.file, this.ikvPath, this.updateProgress);

  Future<void> run() async {
    print(file.path ?? file.name + '\n');
    //   // Chunked json decoding isn't available in web
    //   // var inSink = converterJson.startChunkedConversion(outSink);

    //   var sw = Stopwatch();
    //   var zlib = ZLibEncoder();
    //   sw.start();

    //   try {
    //     updateProgress(0);
    //     if (_canceled) {
    //       runCompleter.complete();
    //       return runCompleter.future;
    //     }
    //     var s = utf8.decode(file.bytes);
    //     print('JSON read (ms): ' + sw.elapsedMilliseconds.toString());
    //     updateProgress(1);
    //     if (_canceled) {
    //       runCompleter.complete();
    //       return runCompleter.future;
    //     }
    //     Map mm = json.decode(s);
    //     Map<String, String> m = mm.cast<String, String>();
    //     print('JSON decoded (ms): ' + sw.elapsedMilliseconds.toString());
    //     updateProgress(5);
    //     var i = 0;
    //     var curr = 0;
    //     Map<String, Uint8List> m2 = {};
    //     for (var e in m.entries) {
    //       if (_canceled) {
    //         runCompleter.complete();
    //         return runCompleter.future;
    //       }
    //       var bytes = utf8.encode(e.value);
    //       var zlibBytes = zlib.encode(bytes);
    //       var b = Uint8List.fromList(zlibBytes);
    //       m2[e.key] = b;
    //       i++;
    //       var p = (i / m.length * 95).round();
    //       if (p != curr) {
    //         curr = p;
    //         //await box.putAll(m2);
    //         var keys = <String>[];
    //         var values = <Uint8List>[];
    //         for (var kv in m2.entries) {
    //           keys.add(kv.key);
    //           values.add(kv.value);
    //         }
    //         m2.clear();
    //         await toFuture(bulkInsert(box.indexedDb, keys, values));
    //         updateProgress(5 + curr);
    //       }
    //     }
    //     if (m2.length > 0) await box.putAll(m2);
    //     var boxName = box.name;
    //     await box.close();
    //     await Hive.openLazyBox<Uint8List>(boxName);
    //     print('Indexing done(ms): ' + sw.elapsedMilliseconds.toString());
    //     runCompleter.complete();
    //   } catch (err) {
    //     _canceled = true;
    //     runCompleter.completeError(err);
    //   }

    return runCompleter.future;
  }
}

class BundledBinaryIndexer extends Indexer {
  final String assetName;
  final Completer<void> runCompleter = Completer<void>();
  final String fileName;
  final Function(int progressPercent) updateProgress;

  BundledBinaryIndexer(this.assetName, this.fileName, this.updateProgress);

  Future<void> run() async {
    print('Indexing bundled bianry dictionary: ' + this.assetName);
    var sw = Stopwatch();
    sw.start();
    var asset = await rootBundle.load(assetName);
    updateProgress(3);
    if (_canceled) {
      runCompleter.complete();
      return runCompleter.future;
    }

    try {
      if (!kIsWeb) {
        File(fileName).writeAsBytesSync(asset.buffer.asInt8List());
        runCompleter.complete();
      } else {
        //TODO
      }

      print('Indexing done(ms): ' + sw.elapsedMilliseconds.toString());
    } catch (err) {
      runCompleter.completeError(err);
    }
    return runCompleter.future;
  }
}
