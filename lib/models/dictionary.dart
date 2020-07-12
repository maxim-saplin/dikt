import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sprintf/sprintf.dart';

class Dictionary extends ChangeNotifier {
  //Map<String, String> words;
  Future loadJson;
  final int maxResults = 100;
  Box<String> _box;

  Dictionary() {
    const fileName = 'assets/En-En-WordNet3-%02i.json';
    const maxFile = 14;
    int file = 0;

    Hive.initFlutter().then((value) {
      Hive.openBox<String>("enRuBig").then((box) {
        _box = box;
        if (_box.isEmpty) {
          iterateJson(fileName, file, maxFile);
        } else
          isLoaded = true;
      }).catchError((e) {
        var err = e;
      });
    });
  }

  void iterateJson(String fileName, int file, int maxFile) {
    var asset = sprintf(fileName, [file]);
    file++;
    loadJson = rootBundle.loadString(asset);
    loadJson.then((value) {
      Map<String, String> words = jsonDecode(value).cast<String, String>();
      _box.putAll(words).then((value) {
        if (file != maxFile)
          iterateJson(fileName, file, maxFile);
        else
          isLoaded = true;
      });
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

  String getArticleFromMatches(int n) {
    if (n > matches.length - 1) return '';
    //return words[matches[n]];
    return _box.get(matches[n]);
  }

  String getArticle(String word) {
    word = word?.toLowerCase();
    if (!_box.containsKey(word)) return '';
    return _box.get(word);
    // if (!words.containsKey(word)) return '';
    // return words[word];
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
