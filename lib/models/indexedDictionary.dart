import 'dart:async';

import 'package:hive/hive.dart';
import 'package:ikvpack/ikvpack.dart';
part 'indexedDictionary.g.dart';

@HiveType(typeId: 0)
class IndexedDictionary extends HiveObject {
  @HiveField(0)
  String ikvPath;
  @HiveField(1)
  bool isEnabled;
  @HiveField(2)
  String name;
  //set to false before starting indexing and to true when done. E.g. if you reload page or close app while indexing it won't be ready and thus won't show up anywhere
  @HiveField(3)
  bool isReadyToUse;
  // error while indexing
  @HiveField(4)
  int order;
  @HiveField(5)
  String hash;

  bool isError = false;
  bool isLoaded = false;
  bool isBundled = false;

  IkvPack _ikv;

  IkvPack get ikv {
    if (!isLoaded) return null;
    return _ikv;
  }

  set ikv(IkvPack value) {
    _ikv = value;
    isLoaded = true;
  }

  Future<IkvPack> openIkv([IsolatePool pool]) async {
    var completer = Completer<IkvPack>();
    if (!isLoaded) {
      var f = pool == null
          ? IkvPack.loadInIsolate(ikvPath)
          : IkvPack.loadInIsolatePool(pool, ikvPath);
      f.then((value) {
        _ikv = value;
        isLoaded = true;
        completer.complete(_ikv);
      }).catchError((e) {
        print('Error loaidinf IkvPack.\n' + e);
        completer.completeError(e);
      });
      return completer.future;
    }
    completer.complete(_ikv);
    return completer.future;
  }

  double get fileSizeMb {
    return ikv.sizeBytes / 1024 / 1024;
  }

  IndexedDictionary();

  IndexedDictionary.init(
      this.ikvPath, this.name, this.isEnabled, this.isReadyToUse);
}
