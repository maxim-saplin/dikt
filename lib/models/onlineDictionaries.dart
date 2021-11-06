import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import '../common/preferences_singleton.dart';
import '../common/debounce_mixin.dart';

class OnlineDictionaryManager extends ChangeNotifier with Debounce {
  static const String defaultUrl =
      'https://ipfs.io/ipfs/QmWByPsvVmTH7fMoSWFxECTWgnYJRcCZmdFzhLNhejqHzm';

  final OnlineRepo _repo;
  final OnlineToOffline _onlineToOffline;

  static const String repoUrlParam = 'repoUrl';

  OnlineDictionaryManager(this._repo, this._onlineToOffline);

  String _repoUrl = '';

  // allow model refresh when navigating betwenn Offline and Online dictionaries UI
  void cleanUp() {
    _repoUrl = '';
    _repoError = null;
    _dictionariesRequested = false;
  }

  String get repoUrl {
    if (_repoUrl.isEmpty)
      _repoUrl = PreferencesSingleton.sp!.getString(repoUrlParam) ?? '';
    if (_repoUrl.isEmpty) {
      return defaultUrl;
    }
    return _repoUrl;
  }

  set repoUrl(String value) {
    debounce(() {
      var err = _repo.verifyUrl(value);

      if (value.isEmpty) {
        _repoError = err;
      } else {
        if (value != _repoUrl) {
          if (err.isNotEmpty) {
            _repoError = err;
          } else {
            _repoUrl = value;
            _loadDictionaries();
            //debounce(_loadDictionaries, 500);
          }
        } else if (err.isEmpty) {
          _loadDictionaries();
          //debounce(_loadDictionaries, 500);
        }
      }
    }, 600);
  }

  void _loadDictionaries() {
    _loading = true;
    _repo.getDictionariesList(repoUrl).then((value) {
      _loading = false;
      _repoError = null;
      _dictionaries = value
          .map((e) => OnlineDictionary(
              e,
              _repo,
              _onlineToOffline,
              _onlineToOffline.isDictionaryDownloaded(e.hash)
                  ? OnlineDictionaryState.downloaded
                  : OnlineDictionaryState.notDownloaded))
          .toList();
      PreferencesSingleton.sp?.setString(repoUrlParam, repoUrl);
    }).catchError((err) {
      _loading = false;
      _repoError = err.toString();
    });
  }

  bool _dictionariesRequested = false;

  List<OnlineDictionary> _dictionaries = [];

  List<OnlineDictionary> get dictionaries {
    if (!_dictionariesRequested) {
      _dictionariesRequested = true;
      Timer.run(() => _loadDictionaries());
    }
    return _dictionaries;
  }

  String? __repoError;

  String? get repoError {
    return __repoError;
  }

  set _repoError(String? value) {
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

class OnlineDictionary extends ChangeNotifier {
  OnlineDictionaryState _state;
  final RepoDictionary repoDictionary;
  final OnlineRepo _repo;
  final OnlineToOffline _onToOff;
  String _nameNotHighlighted = '';
  String _nameHighlighted = '';
  int _bytesDownloaded = 0;
  int _progressPrecent = 0;

  String get nameNotHighlighted => _nameNotHighlighted;
  String get nameHighlighted => _nameHighlighted;
  int get progressPercent => _progressPrecent;

  OnlineDictionary(
      this.repoDictionary, this._repo, this._onToOff, this._state) {
    // EN_EN WordNet 3
    if (repoDictionary.name.length > 4 &&
        repoDictionary.name[5] == ' ' &&
        repoDictionary.name[2] == '_') {
      _nameHighlighted = repoDictionary.name.substring(0, 5);
      if (repoDictionary.name.length > 7) {
        _nameNotHighlighted =
            repoDictionary.name.substring(6, repoDictionary.name.length);
      }
    } else {
      _nameNotHighlighted = repoDictionary.name;
    }
  }

  late RepoDownloader _downloader;

  String? _error;

  String? get error => _error;

  bool _downloadOrIndexingCanceled = false;

  void download() {
    if (_state == OnlineDictionaryState.notDownloaded ||
        _state == OnlineDictionaryState.error) {
      _downloadOrIndexingCanceled = false;

      _state = OnlineDictionaryState.downloading;
      notifyListeners();

      void onError(e) {
        _state = OnlineDictionaryState.error;
        _error = e.toString();
        notifyListeners();
      }

      try {
        _downloader = _repo.downloadDictionary(repoDictionary.url);

        _bytesDownloaded = 0;

        // -1 - unknown length, wait until stream is done
        _progressPrecent = _downloader.length == -1 ? -1 : 0;
        var bytes = BytesBuilder();

        _downloader.bytes!.listen(
            (Uint8List e) {
              _bytesDownloaded += e.length;
              bytes.add(e);
              if (_progressPrecent > -1) {
                var p = (_bytesDownloaded / _downloader.length * 100).round();
                if (p != _progressPrecent) {
                  _progressPrecent = p;
                  notifyListeners();
                }
              }
            },
            cancelOnError: true,
            onError: onError,
            onDone: () {
              if (!_downloadOrIndexingCanceled) {
                _state = OnlineDictionaryState.indexing;
                _progressPrecent = 0;
                notifyListeners();

                _onToOff
                    .indexDictionary(repoDictionary.name, repoDictionary.hash,
                        bytes.takeBytes())
                    .listen(
                        (int p) {
                          _progressPrecent = p;
                          notifyListeners();
                        },
                        cancelOnError: true,
                        onDone: () {
                          if (!_downloadOrIndexingCanceled) {
                            _state = OnlineDictionaryState.downloaded;
                            _progressPrecent = 100;
                            notifyListeners();
                          }
                        },
                        onError: onError);
              }
            });
      } catch (e) {
        onError(e);
      }
    }
  }

  void cancelDownload() {
    if (_state == OnlineDictionaryState.downloading) _downloader.cancel();
    deleteOffline();
  }

  void deleteOffline() {
    if (_state == OnlineDictionaryState.downloaded ||
        _state == OnlineDictionaryState.downloading ||
        _state == OnlineDictionaryState.indexing) {
      _state = OnlineDictionaryState.notDownloaded;

      _downloadOrIndexingCanceled = true;
      notifyListeners();
      _onToOff.cancelIndexingOrDelete(repoDictionary.hash);
    }
  }

  OnlineDictionaryState get state => _state;
}

class RepoDictionary {
  final String url;
  final String name;
  final int words;
  final int sizeBytes;
  final String hash;

  RepoDictionary(this.url, this.name, this.words, this.sizeBytes, this.hash);
}

abstract class RepoDownloader {
  final int length;
  Stream<Uint8List>? _bytes;
  Stream<Uint8List>? get bytes => _bytes;

  @protected
  set bytes(Stream<Uint8List>? value) {
    _bytes = value;
  }

  RepoDownloader(this.length);

  bool _canceled = false;

  bool get canceled => _canceled;

  void cancel() {
    _canceled = true;
  }
}

abstract class OnlineRepo {
  String verifyUrl(String url) {
    if (url.isEmpty) return 'URL can\'t be empty';

    var matches = RegExp(
            r'((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?')
        .allMatches(url);
    if (matches.length != 1) return 'Invalid URL';

    return '';
  }

  Future<List<RepoDictionary>> getDictionariesList(String? url);

  RepoDownloader downloadDictionary(String url);
}

abstract class OnlineToOffline {
  bool isDictionaryDownloaded(String hash);
  Stream<int> indexDictionary(String name, String hash, Uint8List bytes);
  void cancelIndexingOrDelete(String hash);
}
