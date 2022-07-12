import 'dart:async' show Future;
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:ikvpack/ikvpack.dart';

import 'dictionary_manager.dart';

class Article {
  final String word;
  final String article;
  final String dictionaryName;
  Article(this.word, this.article, this.dictionaryName);
}

class MasterDictionary extends ChangeNotifier {
  Future? loadJson;
  final int maxResults = 100;
  late DictionaryManager dictionaryManager;
  double _loadTimeSec = -1;
  double get loadTimeSec => _loadTimeSec;

  void init() {
    debugPrint('Master dictionary init started: ${DateTime.now()}');
    var sw = Stopwatch()..start();
    dictionaryManager.indexAndLoadDictionaries().then((value) {
      isFullyLoaded = true;
      isPartiallyLoaded = true;
      sw.stop();
      debugPrint(
          'Master dictionary init completed: ${DateTime.now()} DURATION(MS): ${sw.elapsedMilliseconds}');
      _loadTimeSec = sw.elapsed.inMilliseconds / 1000;
    });
    dictionaryManager.partiallyLoaded!
        .then((value) => isPartiallyLoaded = true);
  }

  List<String> matches = [];

  int get matchesCount {
    return matches.length;
  }

  int get totalEntries {
    var c = 0;
    for (var i in dictionaryManager.dictionariesEnabled) {
      for (var ikv in i.ikvs) {
        c += ikv.length;
      }
    }
    return c;
  }

  String _lookupWord = '';

  String get lookupWord {
    return _lookupWord;
  }

  bool get isLookupWordEmpty {
    return (_lookupWord == '');
  }

  set lookupWord(String value) {
    if (value == '') {
      _lookupWord = '';
      matches.clear();
      notifyListeners();
    } else {
      value = value.toLowerCase();
      _lookupWord = value;
      _getMatchesForWord(value).whenComplete(() => notifyListeners());
    }
  }

  String _selectedWord = '';

  set selectedWord(String value) {
    value = value.toLowerCase();
    if (value != _selectedWord) {
      _selectedWord = value;
      notifyListeners();
    }
  }

  String get selectedWord {
    return _selectedWord;
  }

  final Stopwatch lookupSw = Stopwatch();

  Future _getMatchesForWord(String lookup) async {
    lookupSw.reset();
    lookupSw.start();

    matches = await IkvPack.consolidatedKeysStartingWith(
        dictionaryManager.ikvPacksLoaded, lookup, maxResults);

    lookupSw.stop();
  }

  String getMatch(int n) {
    if (n > matches.length - 1) return '';
    return matches[n];
  }

  Future<List<Article>?> getArticleFromMatches(int n) async {
    if (n > matches.length - 1) return null;

    var word = matches[n];

    return getArticles(word);
  }

  Future<List<Article>> getArticles(String word) async {
    List<Article> articles = [];

    for (var d in dictionaryManager.dictionariesLoaded) {
      try {
        var s = '';
        for (var i = 0; i < d.ikvs.length; i++) {
          var ikv = d.ikvs[i];
          var ss = (await ikv.getValues(word)).fold<String>(
              '',
              (previousValue, element) => previousValue.isNotEmpty
                  ? '$previousValue</br></br>$element'
                  : element);

          if (s.isNotEmpty && ss.isNotEmpty) {
            ss += '</br></br>';
          }

          s += ss;
        }

        if (s.isNotEmpty) articles.add(Article(word, s, d.name));
      } catch (e) {
        debugPrint('Cant decode value for $word, dictionary ${d.ikvPath}');
        debugPrint(e.toString());
      }
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

Map<String, Uint8List>? isolateBody(IsolateParams params) {
  debugPrint('  JSON loading IN ISOLATE, file ${params.file}');
  //WidgetsFlutterBinding.ensureInitialized();
  var i = 0;
  var zlib = const ZLibEncoder();
  var words = jsonDecode(params.assetValue, reviver: (k, v) {
    if (i % 1000 == 0) debugPrint('  JSON decoded objects: $i');
    i++;
    if (v is String) {
      var bytes = utf8.encode(v);
      var zlibBytes = zlib.encode(bytes);
      var b = Uint8List.fromList(zlibBytes);
      return b;
    } else {
      return v;
    }
  });
  return words.cast<String, Uint8List>();
}
