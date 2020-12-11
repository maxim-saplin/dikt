import 'dart:async';
import 'dart:typed_data';
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

  // allow model refresh when navigating betwenn Offline and Online dictionaries UI
  void cleanUp() {
    _repoUrl = null;
    _repoError = null;
    _dictionariesRequested = false;
  }

  String get repoUrl {
    if (_repoUrl == null)
      _repoUrl = PreferencesSingleton.sp.getString(repoUrlParam);
    if (_repoUrl == null) {
      return defaultUrl;
    }
    return _repoUrl;
  }

  set repoUrl(String value) {
    var err = _repo.verifyUrl(value);

    if (value != _repoUrl) {
      if (err != null) {
        _repoError = err;
      } else {
        _repoUrl = value;
        debounce(_loadDictionaries, 400);
      }
    } else if (err == null) {
      debounce(_loadDictionaries, 400);
    }
  }

  void _loadDictionaries() {
    _loading = true;
    _repo.getDictionariesList(repoUrl).then((value) {
      _loading = false;
      _repoError = null;
      _dictionaries = value.map((e) => OnlineDictionary(e)).toList();
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

enum OnlineDictionaryState {
  notDownloaded,
  downloaded,
  downloading,
  indexing,
  error
}

class OnlineDictionary {
  OnlineDictionaryState _state = OnlineDictionaryState.notDownloaded;
  final RepoDictionary repoDictionary;

  OnlineDictionary(this.repoDictionary);
}

class RepoDictionary {
  final String url;
  final String name;
  final int words;
  final int sizeBytes;
  final String hash;

  RepoDictionary(this.url, this.name, this.words, this.sizeBytes, this.hash);
}

class RepoDownloader {
  final Stream<Uint8List> bytes;
  final int length;

  RepoDownloader(this.bytes, this.length);
}

abstract class OnlineRepo {
  String verifyUrl(String url) {
    if (url == null || url == '') return 'URL can\'t be empty';

    //if (Uri.tryParse(url) == null) return 'Invalid URL';

    var matches = RegExp(
            r'((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?')
        .allMatches(url);
    if (matches.length != 1) return 'Invalid URL';

    return null;
  }

  Future<List<RepoDictionary>> getDictionariesList(String url);

  RepoDownloader downloadDictionary(String url);
}

class FakeOnlineRepo extends OnlineRepo {
  static List<RepoDictionary> dictionaries = [
    RepoDictionary('https://repo.by/1', 'EN_RU Universal Lngv', 100100,
        101 * 1024 * 1024, '1'),
    RepoDictionary('https://repo.by/2', 'RU_EN Universal Lngv', 100200,
        102 * 1024 * 1024, '2'),
    RepoDictionary('https://repo.by/3', 'RU_RU Толковый словарь Даля', 100300,
        103 * 1024 * 1024, '3'),
    RepoDictionary('https://repo.by/4', 'EN_EN WordNet 3.0', 100400,
        104 * 1024 * 1024, '4'),
    RepoDictionary('https://repo.by/5', 'RU_BY Словарь НАН РБ (ред. Крапивы)',
        100500, 105 * 1024 * 1024, '5'),
    RepoDictionary('https://repo.by/6', 'BY_RU Cлоўнік (А. Варвуль)', 100600,
        106 * 1024 * 1024, '6'),
    RepoDictionary('https://repo.by/7', 'BY_BY Тлумачальны слоўнік', 100700,
        107 * 1024 * 1024, '7'),
    RepoDictionary('https://repo.by/8', 'BY_EN Cлоўнік Якуба Коласа', 100800,
        108 * 1024 * 1024, '8'),
    RepoDictionary('https://repo.by/9', 'EN_BY Universal Kolas', 100900,
        109 * 1024 * 1024, '9'),
    RepoDictionary(
        'https://repo.by/10', 'BY_UA Cлоўнік', 101000, 110 * 1024 * 1024, '10'),
  ];

  static const String defaultUrl =
      'https://ipfs.io/ipfs/QmWByPsvVmTH7fMoSWFxECTWgnYJRcCZmdFzhLNhejqHzm';

  static const String secondUrl =
      'https://ipfs.io/ipfs/QmWByPsvVmTH7fMoSWFxECTWgnYJRcCZmdFzhLNhejqHz2';

  static const Duration _timeoutMs = Duration(milliseconds: 2430);

  @override
  Future<List<RepoDictionary>> getDictionariesList(String url) {
    if (url == null) throw 'URL not set';
    if (url == defaultUrl)
      return Future<List<RepoDictionary>>.delayed(
          _timeoutMs, () => dictionaries.toList());

    if (url == secondUrl)
      return Future<List<RepoDictionary>>.delayed(
          _timeoutMs, () => dictionaries.reversed.take(5).toList());

    return Future<List<RepoDictionary>>.delayed(
        _timeoutMs, () => throw 'Repository not available');
  }

  Stream<Uint8List> getBytes(int lengthBytes) async* {
    var chunkSize = (lengthBytes / 100).round();
    var totalSize = 0;

    for (int i = 0; i < 100; i++) {
      totalSize += chunkSize;
      var n = chunkSize;
      if (totalSize > lengthBytes) n = lengthBytes + chunkSize - totalSize;
      await Future.delayed(const Duration(milliseconds: 10));
      yield Uint8List(n);
    }
  }

  @override
  RepoDownloader downloadDictionary(String url) {
    RepoDictionary dic;

    try {
      dic = dictionaries.where((e) => e.url == url).first;
    } catch (_) {
      throw 'Dictionary not found';
    }

    var bytes = getBytes(dic.sizeBytes);

    return RepoDownloader(bytes, dic.sizeBytes);
  }
}
