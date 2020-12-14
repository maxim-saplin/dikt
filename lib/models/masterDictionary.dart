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
  DictionaryManager dictionaryManager;

  void init() {
    print('Master dictionary init started: ' + DateTime.now().toString());
    var sw = Stopwatch()..start();
    dictionaryManager.indexAndLoadDictionaries().then((value) {
      isFullyLoaded = true;
      isPartiallyLoaded = true;
      sw.stop();
      print('Master dictionary init completed: ' +
          DateTime.now().toString() +
          ' DURATION(MS): ' +
          sw.elapsedMilliseconds.toString());
    });
    dictionaryManager.partiallyLoaded.then((value) => isPartiallyLoaded = true);
  }

  List<String> matches = [];

  int get matchesCount {
    return matches.length;
  }

  int get totalEntries {
    var c = 0;
    for (var i in dictionaryManager.dictionariesEnabled)
      if (i.box != null) c += i.box.length;
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

  String _selectedWord;

  set selectedWord(String value) {
    if (value == '' || value == null) {
      _selectedWord = '';
    } else {
      value = value?.toLowerCase();
      _selectedWord = value;
    }
    //notifyListeners();
  }

  String get selectedWord {
    return _selectedWord;
  }

  void _getMatchesForWord(String lookup) {
    lookup = lookup?.toLowerCase();
    int n = 0;
    matches.clear();

    for (var d in dictionaryManager.dictionariesLoaded) {
      for (var k in d.box.keys) {
        if (k.startsWith(lookup) && !matches.contains(k)) {
          n++;
          matches.add(k);
          if (n > maxResults) break;
        }
      }
    }

    matches.sort();
  }

  String getMatch(int n) {
    if (n > matches.length - 1) return '';
    return matches[n];
  }

  Future<String> _unzipIsolate(Uint8List articleBytes) async {
    return await compute(_unzipIsolateBody, articleBytes);
  }

  Future<List<Article>> getArticleFromMatches(int n) async {
    if (n > matches.length - 1) return null;

    var word = matches[n];

    return getArticles(word);
  }

  Future<List<Article>> getArticles(String word) async {
    word = word?.toLowerCase();

    List<Article> articles = [];

    for (var d in dictionaryManager.dictionariesLoaded) {
      var a = await d.box.get(word);
      if (a != null)
        articles.add(Article(word, await _unzipIsolate(a), d.name));
    }

    return articles;
  }

  bool _isFullyLoaded = false;

  // All dictionaries are loaded
  bool get isFullyLoaded {
    return _isFullyLoaded;
  }

  set isFullyLoaded(bool value) {
    if (value != _isFullyLoaded) {
      _isFullyLoaded = value;
      notifyListeners();
    }
  }

  bool _isPartiallyLoaded = false;

  // At least one enabled dictionary is loaded
  bool get isPartiallyLoaded {
    return _isPartiallyLoaded;
  }

  set isPartiallyLoaded(bool value) {
    if (value != _isPartiallyLoaded) {
      _isPartiallyLoaded = value;
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
  var zlib = ZLibEncoder();
  var words = jsonDecode(params.assetValue, reviver: (k, v) {
    if (i % 1000 == 0) print('  JSON decoded objects: ' + i.toString());
    i++;
    if (v is String) {
      var bytes = utf8.encode(v);
      var zlibBytes = zlib.encode(bytes);
      var b = Uint8List.fromList(zlibBytes);
      return b;
    } else
      return v;
  });
  return words.cast<String, Uint8List>();
}

String _unzipIsolateBody(Uint8List articleBytes) {
  //var articleBytes = base64.decode(articleBase64);
  var zlib = ZLibDecoder();
  var bytes = zlib.decodeBytes(articleBytes);
  var article = utf8.decode(bytes);
  return article;
}
