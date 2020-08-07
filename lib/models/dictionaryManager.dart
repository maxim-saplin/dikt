import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:core';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:sprintf/sprintf.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'indexedDictionary.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../common/fileStream.dart';

String nameToBoxName(String name) {
  return 'dik_' + name.replaceAll(RegExp('[^A-Za-z0-9]'), '');
}

class BundledDictionary {
  final String assetFileNamePattern;
  final String name;
  final int maxFileIndex;
  const BundledDictionary(
      this.assetFileNamePattern, this.name, this.maxFileIndex);
  String get boxName {
    return nameToBoxName(name);
  }
}

const bundledDictionaries = [
  BundledDictionary('assets/dictionaries/En-En-WordNet3-%02i.json',
      'EN_EN WordNet 3', 14), //14
  // BundledDictionary(
  //     'assets/dictionaries2/EnRuUniversal%02i.json', 'EN_RU Universal', 9), //9
  // BundledDictionary(
  //     'assets/dictionaries2/RuEnUniversal%02i.json', 'RU_EN Universal', 8), //8
  // BundledDictionary('assets/dictionaries/RuByUniversal%02i.json',
  //     'RU_BY НАН РБ (ред. Крапивы)', 10), //10
];

enum DictionaryBeingProcessedState { pending, inprogress, success, error }

class DictionaryBeingProcessed {
  final String name;
  final BundledDictionary bundledDictiopnary;
  final IndexedDictionary indexedDictionary;
  final File file;

  DictionaryBeingProcessed.bundled(this.bundledDictiopnary)
      : this.name = bundledDictiopnary.name,
        this.file = null,
        this.indexedDictionary = null;

  DictionaryBeingProcessed.indexed(this.indexedDictionary)
      : this.name = indexedDictionary.name,
        this.file = null,
        this.bundledDictiopnary = null;

  DictionaryBeingProcessed.file(this.file)
      : this.name = file.path.split('/').last.replaceFirst('.json', ''),
        this.indexedDictionary = null,
        this.bundledDictiopnary = null;

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

enum ManagerCurrentOperation { preparing, indexing, loading }

class DictionaryManager extends ChangeNotifier {
  static const dictionairesBoxName = 'dictionairesBoxName';
  static Box<IndexedDictionary> _dictionaries;

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(IndexedDictionaryAdapter());
    _dictionaries = await Hive.openBox(dictionairesBoxName);
  }

  Future<void> loadDictionaries() async {
    _isRunning = true;

    _currentOperation = ManagerCurrentOperation.preparing;
    await _checkAndIndexBundledDictionaries();

    _initDictionaryCollections();

    _currentOperation = ManagerCurrentOperation.loading;
    await _loadEnabledDictionaries();

    _isRunning = false;
  }

  void _initDictionaryCollections() {
    _dictionariesReadyList = new List<IndexedDictionary>();
    for (var i = 0; i < _dictionaries.length; i++) {
      var d = _dictionaries.getAt(i);
      if (d.isReadyToUse) _dictionariesReadyList.add(d);
    }
    _sortReadyDictionaries();

    _dictionariesEnabledList = new List<IndexedDictionary>();
    for (var i = 0; i < _dictionariesReadyList.length; i++) {
      var d = _dictionariesReadyList[i];
      if (d.isEnabled) _dictionariesEnabledList.add(d);
    }
  }

  void _sortReadyDictionaries() {
    _dictionariesReadyList.sort((a, b) {
      if (a.order == null || b.order == null) return 0;
      return a.order - b.order;
    });
    var i = 0;
    for (var d in _dictionariesReadyList) {
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
      for (var i in _dictionariesBeingProcessed) {
        try {
          i.state = DictionaryBeingProcessedState.inprogress;
          notifyListeners();
          await Hive.openLazyBox<Uint8List>(i.indexedDictionary.boxName);
          i.state = DictionaryBeingProcessedState.success;
          notifyListeners();
        } catch (err) {
          print("Error loading box: " +
              i.indexedDictionary.boxName +
              "\n" +
              err.toString());

          i.state = DictionaryBeingProcessedState.error;
          notifyListeners();
        }
      }
    }
  }

  Future _checkAndIndexBundledDictionaries() async {
    _dictionariesBeingProcessed = List<DictionaryBeingProcessed>();

    for (var i in bundledDictionaries) {
      if (!_dictionaries.containsKey(i.boxName)) {
        _dictionariesBeingProcessed.add(DictionaryBeingProcessed.bundled(i));
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
      var bd = dictionaryProcessed.bundledDictiopnary;
      return BundledIndexer(bd.assetFileNamePattern, bd.maxFileIndex, box,
          (progress) {
        dictionaryProcessed.progressPercent = progress;
        notifyListeners();
      });
    }

    print('Loading JSON to Hive DB: ' + DateTime.now().toString());
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
        d.isReadyToUse = true;
        d.save();
        dictionariesProcessed[i].state = DictionaryBeingProcessedState.success;
        notifyListeners();
        if (i == dictionariesProcessed.length - 1 && finished != null)
          finished.complete();
      } catch (err) {
        d.isError = true;
        print("Error indexing box: " + d.boxName + "\n" + err.toString());
        dictionariesProcessed[i].state = DictionaryBeingProcessedState.error;
        notifyListeners();
        if (i == dictionariesProcessed.length - 1 && finished != null)
          finished.completeError(err);
      }
    }
  }

  Future<void> loadFromJsonFiles(List<File> files) async {
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
      return FileIndexer(dictionaryProcessed.file, box, (progress) {
        dictionaryProcessed.progressPercent = progress;
        notifyListeners();
      });
    }

    print('Indexing JSON files and loading to Hive DB: ' +
        DateTime.now().toString());
    await _runIndexer(_dictionariesBeingProcessed, getIndexer,
        startOrderAt: 0 - files.length,
        finished: completer); // put dictionaries at the top

    _initDictionaryCollections();

    // if (_canceled) return;

    // _currentOperation = ManagerCurrentOperation.loading;
    // await _loadEnabledDictionaries();

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

  List<IndexedDictionary> _dictionariesReadyList = [];

  List<IndexedDictionary> get dictionariesReady {
    return _dictionariesReadyList;
  }

  List<IndexedDictionary> _dictionariesEnabledList = [];

  List<IndexedDictionary> get dictionariesEnabled {
    return _dictionariesEnabledList;
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
    d.box.deleteFromDisk();
    if (bundledDictionaries.any((e) => e.boxName == d.boxName)) {
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

  bool __isRunning;

  bool get isRunning {
    return __isRunning;
  }

  set _isRunning(bool value) {
    if (value != __isRunning) {
      __isRunning = value;
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
  void cancel() {}
}

class FileIndexer extends Indexer {
  final File file;
  final Completer<void> runCompleter = Completer<void>();
  final LazyBox<Uint8List> box;
  final Function(int progressPercent) updateProgress;
  bool _canceled = false;

  FileIndexer(this.file, this.box, this.updateProgress);

  void cancel() {
    _canceled = true;
  }

  Future<void> run() async {
    print(file.path + '\n');
    var s = FileStream(file.path, null, null);
    var length = await file.length();

    var sw = Stopwatch();

    var converterZip = JsonDecoder((k, v) {
      if (v is String) {
        var bytes = utf8.encode(v);
        var gzipBytes = gzip.encode(bytes);
        var b = Uint8List.fromList(gzipBytes);
        return b;
      } else {
        return v;
      }
    });

    var outSinkZip = ChunkedConversionSink.withCallback((chunks) {
      try {
        var result = chunks.single.cast<String, Uint8List>();
        box.putAll(result);
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

class BundledIndexer extends Indexer {
  final String namePattern;
  //final Completer<void> completer;
  final Completer<void> runCompleter = Completer<void>();
  final LazyBox<Uint8List> box;
  final int maxFile;
  final Function(int progressPercent) updateProgress;

  BundledIndexer(this.namePattern, this.maxFile, this.box, this.updateProgress);

  Future<void> run() async {
    iterateInIsolate();
    return runCompleter.future;
  }

  int _numberOfIsolates = max(2, Platform.numberOfProcessors);
  int _curFile = 0;
  int _runningIsolates = 0;
  int _filesRemaining = 0;

  void iterateInIsolate() {
    if (_curFile == 0) {
      _filesRemaining = maxFile + 1;
      for (var i = 0; i < _numberOfIsolates; i++) {
        if (_curFile > maxFile) break;
        var asset = sprintf(namePattern, [_curFile]);
        isolateProcessBundleAsset(asset, _curFile);
        _curFile++;
      }
    } else {
      if (_curFile > maxFile) return;
      var asset = sprintf(namePattern, [_curFile]);
      isolateProcessBundleAsset(asset, _curFile);
      _curFile++;
    }
  }

  void isolateProcessBundleAsset(String asset, int curFile) async {
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
  var gzip = new GZipEncoder();
  var words = jsonDecode(params.assetValue, reviver: (k, v) {
    if (i % 1000 == 0) print('  JSON decoded objects: ' + i.toString());
    i++;
    if (v is String) {
      var bytes = utf8.encode(v);
      var gzipBytes = gzip.encode(bytes);
      var b = Uint8List.fromList(gzipBytes);
      //if (k is String && k.length > 254) print('>254' + k);
      return b;
    } else
      return v;
  });
  return words.cast<String, Uint8List>();
}
