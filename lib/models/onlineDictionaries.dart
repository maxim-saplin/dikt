import 'dart:async';

import 'package:flutter/foundation.dart';

import '../common/preferencesSingleton.dart';
import '../common/debounceMixin.dart';

class OnlineDictionaryManager extends ChangeNotifier with Debounce {
  static const String defaultUrl =
      'https://ipfs.io/ipfs/QmWByPsvVmTH7fMoSWFxECTWgnYJRcCZmdFzhLNhejqHzm';

  final OnlineRepo _repo;

  static const String repoUrlParam = 'repoUrl';

  OnlineDictionaryManager(this._repo);

  String _repoUrl;

  String get repoUrl {
    if (_repoUrl == null)
      _repoUrl = PreferencesSingleton.sp.getString(repoUrlParam);
    if (_repoUrl == null) return defaultUrl;
    return _repoUrl;
  }

  set repoUrl(String value) {
    if (value != _repoUrl) {
      var err = _repo.verifyUrl(value);

      if (err != null)
        _repoError = err;
      else {
        _repoUrl = value;
        debounce(_loadDictionaries, 400);
      }
    }
  }

  void _loadDictionaries() {
    _loading = true;
    _repo.getDictionariesList(repoUrl).then((value) {
      _loading = false;
      _repoError = null;
      _dictionaries = value;
      PreferencesSingleton.sp.setString(repoUrlParam, repoUrl);
    }).catchError((err) {
      _loading = false;
      _repoError = err.toString();
    });
  }

  bool _dictionariesRequested = false;

  List<OnlineDictionary> _dictionaries;

  List<OnlineDictionary> get dictionaries {
    if (!_dictionariesRequested) {
      _dictionariesRequested = true;
      Timer.run(() => _loadDictionaries());
    }
    return _dictionaries;
  }

  String __repoError;

  String get repoError {
    return __repoError;
  }

  set _repoError(String value) {
    if (value != __repoError) {
      __repoError = value;
      notifyListeners();
    }
  }

  bool __loading = false;

  bool get loading {
    return __loading;
  }

  set _loading(bool value) {
    if (value != __loading) {
      __loading = value;
      notifyListeners();
    }
  }
}

class OnlineDictionary {
  final String url;
  final String name;
  final int words;
  final int sizeBytes;

  OnlineDictionary(this.url, this.name, this.words, this.sizeBytes);
}

abstract class OnlineRepo {
  String verifyUrl(String url) {
    if (url == null || url == '') return 'URL can\'t be empty';

    return null;
  }

  Future<List<OnlineDictionary>> getDictionariesList(String url);
}

class FakeOnlineRepo extends OnlineRepo {
  List<OnlineDictionary> dictionaries = [
    OnlineDictionary(
        'https://repo.by/1', 'Dictionary 1', 100100, 101 * 1024 * 1024),
    OnlineDictionary(
        'https://repo.by/2', 'Dictionary 2', 100200, 102 * 1024 * 1024),
    OnlineDictionary(
        'https://repo.by/3', 'Dictionary 3', 100300, 103 * 1024 * 1024),
    OnlineDictionary(
        'https://repo.by/4', 'Dictionary 4', 100400, 104 * 1024 * 1024),
    OnlineDictionary(
        'https://repo.by/5', 'Dictionary 5', 100500, 105 * 1024 * 1024),
    OnlineDictionary(
        'https://repo.by/6', 'Dictionary 6', 100600, 106 * 1024 * 1024),
    OnlineDictionary(
        'https://repo.by/7', 'Dictionary 7', 100700, 107 * 1024 * 1024),
    OnlineDictionary(
        'https://repo.by/8', 'Dictionary 8', 100800, 108 * 1024 * 1024),
    OnlineDictionary(
        'https://repo.by/9', 'Dictionary 9', 100900, 109 * 1024 * 1024),
    OnlineDictionary(
        'https://repo.by/10', 'Dictionary 10', 101000, 110 * 1024 * 1024),
  ];

  static const String defaultUrl =
      'https://ipfs.io/ipfs/QmWByPsvVmTH7fMoSWFxECTWgnYJRcCZmdFzhLNhejqHzm';

  static const Duration _timeoutMs = Duration(milliseconds: 2430);

  @override
  Future<List<OnlineDictionary>> getDictionariesList(String url) {
    if (url == null) throw 'URL not set';
    if (url == defaultUrl)
      return Future<List<OnlineDictionary>>.delayed(
          _timeoutMs, () => dictionaries.toList());

    return Future<List<OnlineDictionary>>.delayed(
        _timeoutMs, () => throw 'Repository not available');
  }
}
