import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:core';
import 'dart:math';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:sprintf/sprintf.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'indexedDictionary.dart';
import 'bulk_insert/bulk_insert.dart';

import '../common/fileStream.dart';

String nameToBoxName(String name) {
  return 'dik_' + name.replaceAll(RegExp('[^A-Za-z0-9]'), '').toLowerCase();
}

class BundledJsonDictionary {
  final String assetFileNamePattern;
  final String name;
  final int maxFileIndex;
  const BundledJsonDictionary(
      this.assetFileNamePattern, this.name, this.maxFileIndex);
  String get boxName {
    return nameToBoxName(name);
  }
}

const bundledJsonDictionaries = [
  // BundledJsonDictionary('assets/dictionaries/En-En-WordNet3-%02i.json',
  //     'EN_EN WordNet 3', 14), //14
  // BundledJsonDictionary(
  //     'assets/dictionaries2/EnRuUniversal%02i.json', 'EN_RU Universal', 9), //9
  // BundledJsonDictionary(
  //     'assets/dictionaries2/RuEnUniversal%02i.json', 'RU_EN Universal', 8), //8
  // BundledJsonDictionary('assets/dictionaries2/RuByUniversal%02i.json',
  //     'RU_BY НАН РБ (ред. Крапивы)', 10), //10
];

class BundledBinaryDictionary {
  final String assetFileName;
  final String name;
  final String hash;

  const BundledBinaryDictionary(this.assetFileName, this.name, this.hash);
  String get boxName {
    return nameToBoxName(name);
  }
}

const bundledBinaryDictionaries = [
  BundledBinaryDictionary(
      'assets/dictionaries/EnEnWordNet3.json.bundle', 'EN_EN WordNet 3', '4'),
  // BundledBinaryDictionary(
  //     'assets/dictionaries2/EnRuUniversal.json.bundle', 'EN_RU Universal'),
  // BundledBinaryDictionary(
  //     'assets/dictionaries2/RuEnUniversal.json.bundle', 'RU_EN Universal'),
  // BundledBinaryDictionary('assets/dictionaries2/RuByUniversal.json.bundle',
  //     'RU_BY НАН РБ (ред. Крапивы)'),
];

enum DictionaryBeingProcessedState { pending, inprogress, success, error }

class DictionaryBeingProcessed {
  final String name;
  final BundledJsonDictionary bundledJsonDictionary;
  final BundledBinaryDictionary bundledBinaryDictionary;
  final IndexedDictionary indexedDictionary;
  final PlatformFile file;

  DictionaryBeingProcessed.bundledJson(this.bundledJsonDictionary)
      : this.name = bundledJsonDictionary.name,
        this.file = null,
        this.indexedDictionary = null,
        this.bundledBinaryDictionary = null;

  DictionaryBeingProcessed.bundledBinary(this.bundledBinaryDictionary)
      : this.name = bundledBinaryDictionary.name,
        this.file = null,
        this.indexedDictionary = null,
        this.bundledJsonDictionary = null;

  DictionaryBeingProcessed.indexed(this.indexedDictionary)
      : this.name = indexedDictionary.name,
        this.file = null,
        this.bundledJsonDictionary = null,
        this.bundledBinaryDictionary = null;

  DictionaryBeingProcessed.file(this.file)
      : this.name = (file.path ?? file.name)
            .split('/')
            .last
            .split('\\')
            .last
            .replaceFirst('.json', ''),
        this.indexedDictionary = null,
        this.bundledJsonDictionary = null,
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

  static Future<void> init([String testPath]) async {
    if (testPath == null)
      await Hive.initFlutter();
    else
      Hive.init(testPath); // autotests
    Hive.registerAdapter(IndexedDictionaryAdapter());
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
      List<Future<LazyBox<Uint8List>>> futures = [];
      for (var i in _dictionariesBeingProcessed) {
        i.state = DictionaryBeingProcessedState.inprogress;
        notifyListeners();

        var f = Hive.openLazyBox<Uint8List>(i.indexedDictionary.boxName,
            readOnly: true,
            useIsolate: kIsWeb || _dictionariesBeingProcessed.length == 1
                ? false // 1 dictionary, master dictionary inint with isolate 1900ms, without - 1300ms
                : true);

        f.whenComplete(() {
          i.state = DictionaryBeingProcessedState.success;
          i.indexedDictionary.isLoaded = true;
          _initDictionaryCollections();
          if (!_partiallyLoaded.isCompleted) _partiallyLoaded.complete();
          notifyListeners();
        }).catchError((err) {
          print("Error loading box: " +
              i.indexedDictionary.boxName +
              "\n" +
              err.toString());

          i.state = DictionaryBeingProcessedState.error;
          i.indexedDictionary.isError = true;
          notifyListeners();
        });
        futures.add(f);
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

    for (var i in bundledJsonDictionaries) {
      if (!_dictionaries.containsKey(i.boxName)) {
        _dictionariesBeingProcessed
            .add(DictionaryBeingProcessed.bundledJson(i));
      } else {
        _dictionaries.get(i.boxName).isBundled = true;
      }
    }

    for (var i in bundledBinaryDictionaries) {
      if (!_dictionaries.containsKey(i.boxName)) {
        _dictionariesBeingProcessed
            .add(DictionaryBeingProcessed.bundledBinary(i));
      } else {
        _dictionaries.get(i.boxName).isBundled = true;
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
        DictionaryBeingProcessed dictionaryProcessed, LazyBox<Uint8List> box) {
      var bjd = dictionaryProcessed.bundledJsonDictionary;
      var bbd = dictionaryProcessed.bundledBinaryDictionary;
      return bjd != null
          ? BundledJsonIndexer(bjd.assetFileNamePattern, bjd.maxFileIndex, box,
              (progress) {
              dictionaryProcessed.progressPercent = progress;
              notifyListeners();
            })
          : BundledBinaryIndexer(bbd.assetFileName, box, (progress) {
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
          DictionaryBeingProcessed dictionaryProcessed, LazyBox<Uint8List> box),
      {int startOrderAt = 0,
      Completer finished}) async {
    for (var i = 0; i < dictionariesProcessed.length; i++) {
      if (_canceled) break;
      var d = IndexedDictionary();
      d.isBundled = dictionariesProcessed[i].bundledBinaryDictionary != null ||
          dictionariesProcessed[i].bundledJsonDictionary != null;
      if (dictionariesProcessed[i].bundledBinaryDictionary != null) {
        d.hash = dictionariesProcessed[i].bundledBinaryDictionary.hash;
      }
      d.name = dictionariesProcessed[i].name;

      print('  /Dictionary: ' + d.name);

      dictionariesProcessed[i].state = DictionaryBeingProcessedState.inprogress;
      notifyListeners();

      d.boxName = nameToBoxName(d.name);
      d.isEnabled = true;
      d.isReadyToUse = false;
      d.order = startOrderAt + i;

      _dictionaries.put(d.boxName, d);
      var box = await Hive.openLazyBox<Uint8List>(d.boxName);
      _curIndexer = getIndexer(dictionariesProcessed[i], box);
      try {
        await _curIndexer.run();

        if (!_curIndexer.canceled) {
          d.isReadyToUse = true;
          d.isLoaded = true;

          d.save();
        } else if (!d.isBundled) {
          _dictionaries.delete(d.boxName);
          d.delete();
        }
        dictionariesProcessed[i].state = DictionaryBeingProcessedState.success;
        notifyListeners();
        if (i == dictionariesProcessed.length - 1 && finished != null)
          finished.complete();
      } catch (err) {
        d.isError = true;

        if (!d.isBundled) {
          _dictionaries.delete(d.boxName);
          d.delete();
        }

        print("Error indexing box: " + d.boxName + "\n" + err.toString());
        dictionariesProcessed[i].state = DictionaryBeingProcessedState.error;
        notifyListeners();
        if (i == dictionariesProcessed.length - 1 && finished != null)
          finished.completeError(err);
      }
    }
  }

  Future<void> loadFromJsonFiles(List<PlatformFile> files) async {
    _isRunning = true;
    _canceled = false;
    _dictionariesBeingProcessed = [];
    var completer = Completer();

    _currentOperation = ManagerCurrentOperation.preparing;
    notifyListeners();

    print('Processing JSON files: ' + DateTime.now().toString());

    for (var f in files) {
      _dictionariesBeingProcessed.add(DictionaryBeingProcessed.file(f));
    }

    _currentOperation = ManagerCurrentOperation.indexing;

    Indexer getIndexer(
        DictionaryBeingProcessed dictionaryProcessed, LazyBox<Uint8List> box) {
      var progress = (progress) {
        dictionaryProcessed.progressPercent = progress;
        notifyListeners();
      };

      return kIsWeb
          ? WebIndexer(dictionaryProcessed.file, box, progress)
          : FileIndexer(dictionaryProcessed.file, box, progress);
    }

    print('Indexing JSON files and loading to Hive DB: ' +
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
    Hive.deleteBoxFromDisk(d.boxName);
    //d.box.deleteFromDisk();
    if (bundledJsonDictionaries.any((e) => e.boxName == d.boxName)) {
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

class FileIndexer extends Indexer {
  final PlatformFile file;
  final Completer<void> runCompleter = Completer<void>();
  final LazyBox<Uint8List> box;
  final Function(int progressPercent) updateProgress;

  FileIndexer(this.file, this.box, this.updateProgress);

  Future<void> run() async {
    var path = this.file.path ?? this.file.name;
    print(path + '\n');
    var file = File(path);
    var s = FileStream(path, null, null);
    var length = await file.length();

    var zlib = ZLibEncoder();

    var sw = Stopwatch();

    var converterZip = JsonDecoder((k, v) {
      if (v is String) {
        var bytes = utf8.encode(v);
        var zlibBytes = zlib.encode(bytes);
        var b = Uint8List.fromList(zlibBytes);
        return b;
      } else {
        return v;
      }
    });

    var outSinkZip = ChunkedConversionSink.withCallback((chunks) async {
      try {
        var result = chunks.single.cast<String, Uint8List>();
        await box.putAll(result);
        sw.stop();
        runCompleter.complete();
        print('ELAPSED (ms): ' + sw.elapsedMilliseconds.toString());
      } catch (err) {
        _canceled = true;
        runCompleter.completeError(err);
      }
    });

    sw.start();
    var inSinkZip = converterZip.startChunkedConversion(outSinkZip);

    var progress = -1;
    var utf = s.transform(utf8.decoder);
    StreamSubscription<String> subscription;

    subscription = utf.listen((event) {
      try {
        if (_canceled) subscription?.cancel();
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
  final LazyBox<Uint8List> box;
  final Function(int progressPercent) updateProgress;

  WebIndexer(this.file, this.box, this.updateProgress);

  Future<void> run() async {
    print(file.path ?? file.name + '\n');
    // Chunked json decoding isn't available in web
    // var inSink = converterJson.startChunkedConversion(outSink);

    var sw = Stopwatch();
    var zlib = ZLibEncoder();
    sw.start();

    try {
      updateProgress(0);
      if (_canceled) return null;
      var s = utf8.decode(file.bytes);
      print('JSON read (ms): ' + sw.elapsedMilliseconds.toString());
      updateProgress(1);
      if (_canceled) return null;
      Map mm = json.decode(s);
      Map<String, String> m = mm.cast<String, String>();
      print('JSON decoded (ms): ' + sw.elapsedMilliseconds.toString());
      updateProgress(5);
      var i = 0;
      var curr = 0;
      Map<String, Uint8List> m2 = {};
      for (var e in m.entries) {
        if (_canceled) return null;
        var bytes = utf8.encode(e.value);
        var zlibBytes = zlib.encode(bytes);
        var b = Uint8List.fromList(zlibBytes);
        m2[e.key] = b;
        i++;
        var p = (i / m.length * 95).round();
        if (p != curr) {
          curr = p;
          //await box.putAll(m2);
          var keys = <String>[];
          var values = <Uint8List>[];
          for (var kv in m2.entries) {
            keys.add(kv.key);
            values.add(kv.value);
          }
          m2.clear();
          await toFuture(bulkInsert(box.indexedDb, keys, values));
          updateProgress(5 + curr);
        }
      }
      if (m2.length > 0) await box.putAll(m2);
      var boxName = box.name;
      await box.close();
      await Hive.openLazyBox<Uint8List>(boxName);
      print('Indexing done(ms): ' + sw.elapsedMilliseconds.toString());
      runCompleter.complete();
    } catch (err) {
      _canceled = true;
      runCompleter.completeError(err);
    }

    return runCompleter.future;
  }
}

class BundledBinaryIndexer extends Indexer {
  final String assetName;
  final Completer<void> runCompleter = Completer<void>();
  final LazyBox<Uint8List> box;
  final Function(int progressPercent) updateProgress;

  BundledBinaryIndexer(this.assetName, this.box, this.updateProgress);

  Future<void> run() async {
    print('Indexing bundled bianry dictionary: ' + this.assetName);
    var sw = Stopwatch();
    sw.start();
    var file = await rootBundle.load(assetName);
    updateProgress(3);
    if (_canceled) return null;

    try {
      var m = Map<String, Uint8List>();
      var keys = <String>[];
      var values = <Uint8List>[];
      var position = 0;

      var count = file.getInt32(position);
      position += 4;
      print(count);
      var counter = 0;
      var curr = 0;

      var db = box.indexedDb;
      while (position < file.lengthInBytes - 1 && counter < count) {
        counter++;

        var length = file.getInt32(position);
        position += 4;
        var bytes = file.buffer.asUint8List(position, length);
        var key = utf8.decode(bytes);
        position += length;

        length = file.getInt32(position);
        position += 4;
        bytes = file.buffer.asUint8List(position, length).sublist(0, length);

        position += length;

        // indexedDB inserts via Hive are super slow.
        // Directly inserting to indexDB via JS interop.
        // Since Maps are broken when marshaled in dart2js, using 2 arrays instead
        if (kIsWeb) {
          keys.add(key);
          values.add(bytes);
        } else {
          m[key] = bytes;
        }
        var p = (counter / count * 97).round();
        if (p != curr) {
          if (_canceled) return null;
          curr = p;
          if (kIsWeb) {
            await toFuture(bulkInsert(db, keys, values));
            keys.clear();
            values.clear();
          } else {
            await box.putAll(m);
            m.clear();
          }
          updateProgress(3 + curr);
        }
      }
      if (kIsWeb) {
        if (keys.length > 0) await toFuture(bulkInsert(db, keys, values));
        box.close(); // Force reload to get keys in Box
      } else if (m.length > 0) await box.putAll(m);

      print('Indexing done(ms): ' + sw.elapsedMilliseconds.toString());

      runCompleter.complete();
    } catch (err) {
      runCompleter.completeError(err);
    }
    return runCompleter.future;
  }
}

class BundledJsonIndexer extends Indexer {
  final String namePattern;
  final Completer<void> runCompleter = Completer<void>();
  final LazyBox<Uint8List> box;
  final int maxFile;
  final Function(int progressPercent) updateProgress;

  BundledJsonIndexer(
      this.namePattern, this.maxFile, this.box, this.updateProgress);

  Future<void> run() async {
    iterateInIsolate();
    return runCompleter.future;
  }

  int _numberOfIsolates = max(2, kIsWeb ? 2 : Platform.numberOfProcessors);
  int _curFile = 0;
  int _runningIsolates = 0;
  int _filesRemaining = 0;

  void iterateInIsolate() {
    if (_curFile == 0) {
      _filesRemaining = maxFile + 1;
      for (var i = 0; i < _numberOfIsolates; i++) {
        if (_curFile > maxFile) break;
        var asset = sprintf(namePattern, [_curFile]);
        isolateProcessBundledJsonAsset(asset, _curFile);
        _curFile++;
      }
    } else {
      if (_curFile > maxFile) return;
      var asset = sprintf(namePattern, [_curFile]);
      isolateProcessBundledJsonAsset(asset, _curFile);
      _curFile++;
    }
  }

  void isolateProcessBundledJsonAsset(String asset, int curFile) async {
    _runningIsolates++;
    _filesRemaining--;
    try {
      var assetValue = await rootBundle.loadString(asset);
      var computeValue =
          await compute(isolateBody, IsolateParams(assetValue, curFile));
      _runningIsolates--;
      if (_runningIsolates == 0 && _filesRemaining == 0) {
        await box.putAll(computeValue);
        if (updateProgress != null) updateProgress(100);
        //completer?.complete();
        runCompleter.complete();
        print('JSON loaded to Hive DB: ' + DateTime.now().toString());
      } else {
        box.putAll(computeValue);
        if (updateProgress != null)
          updateProgress(
              (100 - (_filesRemaining + _runningIsolates) / (maxFile + 1) * 100)
                  .round());
        if (_filesRemaining > 0) iterateInIsolate();
      }
    } catch (err) {
      if (!runCompleter.isCompleted) runCompleter.completeError(err);
      _filesRemaining = 0;
    }
  }
}

Map<String, Uint8List> isolateBody(IsolateParams params) {
  print('  JSON loading IN ISOLATE, file ' + params.file.toString());
  //WidgetsFlutterBinding.ensureInitialized();
  var i = 0;
  var zlib = new ZLibEncoder();
  var words = jsonDecode(params.assetValue, reviver: (k, v) {
    if (i % 1000 == 0) print('  JSON decoded objects: ' + i.toString());
    i++;
    if (v is String) {
      var bytes = utf8.encode(v);
      var zlibBytes = zlib.encode(bytes);
      var b = Uint8List.fromList(zlibBytes);
      //if (k is String && k.length > 254) print('>254' + k);
      return b;
    } else
      return v;
  });
  return words.cast<String, Uint8List>();
}
