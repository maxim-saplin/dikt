import 'package:flutter/foundation.dart';

import '../common/preferencesSingleton.dart';

class OnlineDictionaries extends ChangeNotifier {
  static const String defaultUrl =
      'https://ipfs.io/ipfs/QmWByPsvVmTH7fMoSWFxECTWgnYJRcCZmdFzhLNhejqHzm';

  final OnlineRepo _repo;

  static const String repoUrlParam = 'repoUrl';

  OnlineDictionaries(this._repo);

  String _repoUrl;

  String get repoUrl {
    if (_repoUrl == null)
      _repoUrl = PreferencesSingleton.sp.getString(repoUrlParam);
    if (_repoUrl == null) return defaultUrl;
    return _repoUrl;
  }

  set repoUrl(String value) {
    if (value != _repoUrl) {
      try {
        _repo.setAndVerifyUrl(value);
        _repoOk = true;
      } catch (_) {
        _repoOk = false;
      }

      _repoUrl = value;
      PreferencesSingleton.sp.setString(repoUrlParam, value);

      notifyListeners();
    }
  }

  List<OnlineDictionary> get dictionaries {
    return null;
  }

  bool _repoOk = false;

  bool get repoOk {
    return _repoOk;
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
  String _url;

  String get url {
    return _url;
  }

  void setAndVerifyUrl(value) {
    _url = value;
  }

  List<OnlineDictionary> getDictionariesList();
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

  @override
  List<OnlineDictionary> getDictionariesList() {
    if (url == null) throw 'URL not set';
    if (url == defaultUrl) return dictionaries.toList();

    throw 'Repository not available';
  }
}
