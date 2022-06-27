import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:ikvpack/ikvpack.dart';
part 'indexed_dictionary.g.dart';

const String _separator = '␞';

@HiveType(typeId: 0)
class IndexedDictionary extends HiveObject {
  @HiveField(0)
  String ikvPath = '';
  @HiveField(1)
  bool isEnabled = false;
  @HiveField(2)
  String name = '';
  //set to false before starting indexing and to true when done. E.g. if you reload page or close app while indexing it won't be ready and thus won't show up anywhere
  @HiveField(3)
  bool isReadyToUse = false;
  // error while indexing
  @HiveField(4)
  int order = -1;
  @HiveField(5)
  String hash = '';

  bool isError = false;
  bool _isLoaded = false;
  bool isLoading = false;
  bool isBundled = false;

  bool get isLoaded => _isLoaded;

  int get parts {
    if (ikvPath.contains(_separator)) {
      var n = ikvPath.substring(ikvPath.indexOf(_separator, ikvPath.length));
    }
    return 1;
  }

  IkvPack? _ikv;

  IkvPack? get ikv {
    return _ikv;
  }

  set ikv(IkvPack? value) {
    _ikv = value;
    _isLoaded = value != null;
  }

  Future<IkvPack> openIkv([IsolatePool? pool]) async {
    var completer = Completer<IkvPack>();
    if (!_isLoaded) {
      isLoading = true;
      var f = kIsWeb
          ? IkvPack.load(ikvPath)
          : (pool == null
              ? IkvPack.loadInIsolate(ikvPath)
              : IkvPackProxy.loadInIsolatePoolAndUseProxy(
                  pool, ikvPath)); //IkvPack.loadInIsolatePool(pool, ikvPath));
      f.then((value) {
        _ikv = value;
        _isLoaded = true;
        isLoading = false;
        completer.complete(_ikv);
      }).catchError((e) {
        print('Error loaiding IkvPack.\n' + e.toString());
        isLoading = false;
        completer.completeError(e);
      });
      return completer.future;
    }
    completer.complete(_ikv);
    return completer.future;
  }

  Future<IkvInfo> getInfo() {
    // can throw
    return IkvPack.getInfo(ikvPath);
  }

  IndexedDictionary();

  IndexedDictionary.init(
      this.ikvPath, this.name, this.isEnabled, this.isReadyToUse);
}
