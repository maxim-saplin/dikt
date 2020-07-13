import 'dart:async' show Future;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sprintf/sprintf.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';

class MasterDictionary extends ChangeNotifier {
  //Map<String, String> words;
  Future loadJson;
  final int maxResults = 100;
  LazyBox<Uint8List> _box;
  GZipDecoder _gZipDecoder = GZipDecoder();

  MasterDictionary() {
    const fileName = 'assets/En-En-WordNet3-%02i.json';
    const maxFile = 14;
    //int file = 0;

    print('Hive init: ' + DateTime.now().toString());
    Hive.initFlutter().then((value) {
      Hive.openLazyBox<Uint8List>("enRuBig").then((box) {
        _box = box;
        if (_box.isEmpty) {
          print('Loading JSON to Hive DB: ' + DateTime.now().toString());
          //iterateJson(fileName, file, maxFile);
          iterateInIsolate(fileName, maxFile);
        } else {
          isLoaded = true;
          print('JSON was already loaded to Hive DB: ' +
              DateTime.now().toString());
        }
      }).catchError((e) {
        var err = e;
      });
    });
  }

  int _numberOfIsolates = 4;
  int _curFile = 0;
  int _runningIsolates = 0;
  int _filesRemaining = 0;

  void iterateInIsolate(String fileName, int maxFile) {
    if (_curFile == 0) {
      _filesRemaining = maxFile + 1;
      for (var i = 0; i < _numberOfIsolates; i++) {
        if (_curFile > maxFile) break;
        var asset = sprintf(fileName, [_curFile]);
        isolateProcessBundleAsset(asset, fileName, _curFile, maxFile);
        _curFile++;
      }
    } else {
      if (_curFile > maxFile) return;
      var asset = sprintf(fileName, [_curFile]);
      isolateProcessBundleAsset(asset, fileName, _curFile, maxFile);
      _curFile++;
    }
  }

  void isolateProcessBundleAsset(
      String asset, String fileName, int curFile, int maxFile) {
    _runningIsolates++;
    _filesRemaining--;
    rootBundle.loadString(asset).then((assetValue) {
      compute(isolateBody, IsolateParams(assetValue, curFile)).then((value) {
        _runningIsolates--;
        if (_runningIsolates == 0 && _filesRemaining == 0) {
          _box.putAll(value).then((value) {
            isLoaded = true;
            print('JSON loaded to Hive DB: ' + DateTime.now().toString());
          });
        } else {
          _box.putAll(value);
          if (_filesRemaining > 0) iterateInIsolate(fileName, maxFile);
        }
      });
    });
  }

  // void iterateJson(String fileName, int file, int maxFile) {
  //   print('  JSON loading, iteration ' +
  //       file.toString() +
  //       ' of ' +
  //       maxFile.toString());
  //   var asset = sprintf(fileName, [file]);
  //   file++;
  //   loadJson = rootBundle.loadString(asset);
  //   loadJson.then((value) {
  //     var i = 0;
  //     var gzip = new GZipEncoder();
  //     // still there's Map of string create and stored internally which is passed to the method at the end of decoding, though returning nulls should save mem
  //     jsonDecode(value, reviver: (k, v) {
  //       //try {
  //       if (i % 1000 == 0) print('  JSON decoded objects: ' + i.toString());
  //       i++;
  //       if (v is String) {
  //         var bytes = utf8.encode(v);
  //         var gzipBytes = gzip.encode(bytes);
  //         var s = base64.encode(gzipBytes);
  //         _box.put(k as String, s);
  //       }
  //       // } catch (error) {
  //       //   var err = error;
  //       // }
  //       return null;
  //     });
  //     if (file != maxFile + 1)
  //       iterateJson(fileName, file, maxFile);
  //     else {
  //       isLoaded = true;
  //       print('JSON loaded to Hive DB: ' + DateTime.now().toString());
  //     }
  //   });
  // }

  List<String> matches = [];

  int get matchesCount {
    return matches.length;
  }

  int get totalWords {
    return _box.length;
  }

  String _lookupWord = '';

  String get lookupWord {
    return _lookupWord;
  }

  bool get isLookupWordEmpty {
    return (_lookupWord == null || _lookupWord == '');
  }

  set lookupWord(String value) {
    if (value == '' || value == null) {
      _lookupWord = '';
      matches.clear();
    } else {
      value = value?.toLowerCase();
      _lookupWord = value;
      _getMatchesForWord(value);
    }
    notifyListeners();
  }

  void _getMatchesForWord(String lookup) {
    lookup = lookup?.toLowerCase();
    int n = 0;
    matches.clear();

    //for (var k in words.keys) {
    for (var k in _box.keys) {
      if (k.startsWith(lookup)) {
        n++;
        matches.add(k);
        if (n > maxResults) break;
      }
    }
  }

  String getMatch(int n) {
    if (n > matches.length - 1) return '';
    return matches[n];
  }

  Future<String> _unzip(Uint8List articleBytes) async {
    //var articleBytes = base64.decode(articleBase64);
    var bytes = _gZipDecoder.decodeBytes(articleBytes);
    var article = utf8.decode(bytes);
    return article;
  }

  Future<String> getArticleFromMatches(int n) async {
    if (n > matches.length - 1) return null; //Future<String>.value('');
    var article = _unzip(await _box.get(matches[n]));
    return article;
  }

  Future<String> getArticle(String word) async {
    word = word?.toLowerCase();
    if (!_box.containsKey(word)) return null; //Future<String>.value('');
    var article = _unzip(await _box.get(word));
    return article;
  }

  bool _isLoaded = false;

  bool get isLoaded {
    return _isLoaded;
  }

  set isLoaded(bool value) {
    if (value != _isLoaded) {
      _isLoaded = value;
      notifyListeners();
    }
  }

  void notify() {
    notifyListeners();
  }
}

class IsolateParams {
  const IsolateParams(this.assetValue, this.file);
  final String assetValue;
  final int file;
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
      return b;
      //var s = base64.encode(gzipBytes);
      //return s;
    } else
      return v;
  });
  return words.cast<String, Uint8List>();
}
