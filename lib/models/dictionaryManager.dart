import 'dart:async' show Future, Completer;
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

class BundledDictionary {
  final String assetFileNamePattern;
  final String name;
  final int maxFileIndex;
  const BundledDictionary(
      this.assetFileNamePattern, this.name, this.maxFileIndex);
  String get boxName {
    return 'dik_' + name.replaceAll(RegExp('[^A-Za-z0-9]'), '');
  }
}

const bundledDictionaries = [
  BundledDictionary(
      'assets/dictionaries/EnRuUniversal%02i.json', 'EN/RU Universal', 9), //9
  BundledDictionary('assets/dictionaries/En-En-WordNet3-%02i.json',
      'EN/EN WordNet 3', 14), //14
  BundledDictionary(
      'assets/dictionaries/RuEnUniversal%02i.json', 'RU/EN Universal', 8), //8
];

class DictionaryManager extends ChangeNotifier {
  static const dictionairesBoxName = 'dictionairesBoxName';
  static Box<IndexedDictionary> _dictionaries;

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(IndexedDictionaryAdapter());
    _dictionaries = await Hive.openBox(dictionairesBoxName);
  }

  Future<void> loadBundledDictionaries() async {
    _isRunning = true;
    var completer = Completer<void>();

    if (_dictionaries.length == bundledDictionaries.length) {
      //TODO: make proper vefication{
      for (var i = 0; i < _dictionaries.length; i++) {
        var d = _dictionaries.getAt(i);
        await Hive.openLazyBox<Uint8List>(d.boxName);
      }
      completer.complete();
    } else {
      print('Loading JSON to Hive DB: ' + DateTime.now().toString());
      for (var i = 0; i < bundledDictionaries.length; i++) {
        var d = IndexedDictionary();
        var bd = bundledDictionaries[i];
        d.name = bd.name;
        d.boxName = bd.boxName;
        d.enabled = true;
        d.isReadyToUse = false;
        d.order = i;
        _dictionaries.put(d.boxName, d);
      }

      for (var i = 0; i < _dictionaries.length; i++) {
        var bd = bundledDictionaries[i];
        var d = _dictionaries.get(bd.boxName);
        var box = await Hive.openLazyBox<Uint8List>(d.boxName);
        var indexer = BundledIndexer(bd.assetFileNamePattern, bd.maxFileIndex,
            i == bundledDictionaries.length - 1 ? completer : null, box);
        try {
          await indexer.run();
          d.isReadyToUse = true;
          d.save();
        } catch (err) {
          d.isError = true;
        }
      }
    }

    _isRunning = false;

    return completer.future;
  }

  List<IndexedDictionary> _dictionariesList = [];

  List<IndexedDictionary> get dictionaries {
    if (_dictionariesList.length != _dictionaries.length) {
      _dictionariesList = new List<IndexedDictionary>();
      for (var i = 0; i < _dictionaries.length; i++) {
        var d = _dictionaries.getAt(i);
        _dictionariesList.add(d);
      }
      _dictionariesList.sort((a, b) {
        if (a.order == null || b.order == null) return 0;
        return a.order - b.order;
      });
    }
    return _dictionariesList;
  }

  bool __isRunning;

  bool get isRunning {
    return __isRunning;
  }

  set _isRunning(bool value) {
    if (value != __isRunning) {
      __isRunning = value;
    }
  }
}

class IsolateParams {
  const IsolateParams(this.assetValue, this.file);
  final String assetValue;
  final int file;
}

class BundledIndexer {
  final String namePattern;
  final Completer<void> completer;
  final Completer<void> runCompleter = Completer<void>();
  final LazyBox<Uint8List> box;
  final int maxFile;

  BundledIndexer(this.namePattern, this.maxFile, this.completer, this.box);

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
        //isLoaded = true;
        completer?.complete();
        runCompleter.complete();
        print('JSON loaded to Hive DB: ' + DateTime.now().toString());
      } else {
        box.putAll(computeValue);
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
