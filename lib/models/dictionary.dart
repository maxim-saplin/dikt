import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class Dictionary extends ChangeNotifier {
  Map<String, String> words;
  Future loadJson;
  final int maxResults = 100;

  Dictionary() {
    loadJson = rootBundle.loadString('assets/dictionary_compact.json');
    loadJson.then((value) {
      words = jsonDecode(value).cast<String, String>();
      isLoaded = true;
    }).catchError((e) {
      var err = e;
    });
  }

  List<String> matches = [];

  int get matchesCount {
    return matches.length;
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
      _lookupWord = value;
      _getMatchesForWord(value);
    }
    notifyListeners();
  }

  void _getMatchesForWord(String lookup) {
    int n = 0;
    matches.clear();

    for (var k in words.keys) {
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

  String getArticleFromMatches(int n) {
    if (n > matches.length - 1) return '';
    return words[matches[n]];
  }

  String getArticle(String word) {
    return words[word];
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
}
