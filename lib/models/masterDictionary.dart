import 'dart:async' show Future;
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import './dictionaryManager.dart';

class Article {
  final String word;
  final String article;
  final String dictionaryName;
  Article(this.word, this.article, this.dictionaryName);
}

class MasterDictionary extends ChangeNotifier {
  Future loadJson;
  final int maxResults = 100;
  //LazyBox<Uint8List> _box;
  GZipDecoder _gZipDecoder = GZipDecoder();
  DictionaryManager dictionaryManager;

  MasterDictionary() {
    /*  const fileName = 'assets/En-En-WordNet3-%02i.json';
    const maxFile = 14;

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
    });*/
  }

  void init() {
    dictionaryManager
        .loadBundledDictionaries()
        .then((value) => isLoaded = true);
  }

  // int _numberOfIsolates = 4;
  // int _curFile = 0;
  // int _runningIsolates = 0;
  // int _filesRemaining = 0;

  // void iterateInIsolate(String fileName, int maxFile) {
  //   if (_curFile == 0) {
  //     _filesRemaining = maxFile + 1;
  //     for (var i = 0; i < _numberOfIsolates; i++) {
  //       if (_curFile > maxFile) break;
  //       var asset = sprintf(fileName, [_curFile]);
  //       isolateProcessBundleAsset(asset, fileName, _curFile, maxFile);
  //       _curFile++;
  //     }
  //   } else {
  //     if (_curFile > maxFile) return;
  //     var asset = sprintf(fileName, [_curFile]);
  //     isolateProcessBundleAsset(asset, fileName, _curFile, maxFile);
  //     _curFile++;
  //   }
  // }

  // void isolateProcessBundleAsset(
  //     String asset, String fileName, int curFile, int maxFile) {
  //   _runningIsolates++;
  //   _filesRemaining--;
  //   rootBundle.loadString(asset).then((assetValue) {
  //     compute(isolateBody, IsolateParams(assetValue, curFile)).then((value) {
  //       _runningIsolates--;
  //       if (_runningIsolates == 0 && _filesRemaining == 0) {
  //         _box.putAll(value).then((value) {
  //           isLoaded = true;
  //           print('JSON loaded to Hive DB: ' + DateTime.now().toString());
  //         });
  //       } else {
  //         _box.putAll(value);
  //         if (_filesRemaining > 0) iterateInIsolate(fileName, maxFile);
  //       }
  //     });
  //   });
  // }

  List<String> matches = [];

  int get matchesCount {
    return matches.length;
  }

  int get totalEntries {
    var c = 0;
    for (var i in dictionaryManager.dictionaries) c += i.box.length;
    return c;
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
    for (var d in dictionaryManager.dictionaries) {
      //TODO: consider interleaving
      for (var k in d.box.keys) {
        if (k.startsWith(lookup) && !matches.contains(k)) {
          n++;
          matches.add(k);
          if (n > maxResults) break;
        }
      }
    }
    // for (var k in _box.keys) {
    //   if (k.startsWith(lookup)) {
    //     n++;
    //     matches.add(k);
    //     if (n > maxResults) break;
    //   }
    // }
  }

  String getMatch(int n) {
    if (n > matches.length - 1) return '';
    return matches[n];
  }

  String _unzip(Uint8List articleBytes) {
    //var articleBytes = base64.decode(articleBase64);
    var bytes = _gZipDecoder.decodeBytes(articleBytes);
    var article = utf8.decode(bytes);
    return article;
  }

  Future<String> _unzipIsolate(Uint8List articleBytes) async {
    return await compute(_unzipIsolateBody, articleBytes);
  }

  Future<List<Article>> getArticleFromMatches(int n) async {
    if (n > matches.length - 1) return null;

    var word = matches[n];

    return getArticles(word);
    // if (n > matches.length - 1) return null; //Future<String>.value('');
    // var article = _unzip(await _box.get(matches[n]));
    // return article;
  }

  Future<List<Article>> getArticles(String word) async {
    word = word?.toLowerCase();

    List<Article> articles = [];

    for (var d in dictionaryManager.dictionaries) {
      var a = await d.box.get(word);
      if (a != null)
        articles.add(Article(word, await _unzipIsolate(a), d.name));
    }

    return articles;
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
  var gzip = GZipEncoder();
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

String _unzipIsolateBody(Uint8List articleBytes) {
  //var articleBytes = base64.decode(articleBase64);
  var gZipDecoder = GZipDecoder();
  var bytes = gZipDecoder.decodeBytes(articleBytes);
  var article = utf8.decode(bytes);
  return article;
}
