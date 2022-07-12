import 'package:dikt/common/preferences_singleton.dart';
import 'dart:async';

import 'package:flutter/material.dart';

class History extends ChangeNotifier {
  final int maxWords = 100;
  static const String _historyParam = 'history';

  List<String> _words = [];
  bool preferencesLoaded = false;

  int get wordsCount {
    if (!preferencesLoaded) {
      var list = PreferencesSingleton.sp!.getStringList(_historyParam);
      if (list != null) _words = list;
      preferencesLoaded = true;
    }
    return _words.length;
  }

  String getWord(int n) {
    if (n > _words.length - 1) return '';
    return _words[_words.length - n - 1];
  }

  void addWord(String word) {
    word = word.toLowerCase();
    if (_words.contains(word)) {
      _words.remove(word);
    }

    if (_words.length > maxWords) {
      _words.removeAt(0);
    }
    _words.add(word);
    Timer.run(
        () => PreferencesSingleton.sp!.setStringList(_historyParam, _words));
  }

  void clear() {
    _words = [];
    PreferencesSingleton.sp!.remove(_historyParam);
    notifyListeners();
  }

  void removeWord(String word) {
    word = word.toLowerCase();
    if (_words.contains(word)) {
      _words.remove(word);
    }
  }
}
