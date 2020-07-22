import 'dart:typed_data';
import 'dart:io';
import 'package:hive/hive.dart';

part 'indexedDictionary.g.dart';

@HiveType(typeId: 0)
class IndexedDictionary extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  bool isEnabled;
  @HiveField(2)
  String boxName;
  @HiveField(3)
  bool
      isReadyToUse; //e.g. indexing can fail in the process, created though not complete box must be deleted
  bool isError;

  //LazyBox<Uint8List> _box = null;

  LazyBox<Uint8List> get box {
    //return _box;
    return Hive.lazyBox<Uint8List>(boxName);
  }

  Future<LazyBox<Uint8List>> openBox() async {
    if (!Hive.isBoxOpen(boxName)) return await Hive.openLazyBox(boxName);
    return box;
  }

  double get fileSizeMb {
    var file = File(box.path);
    return file.lengthSync() / 1024 / 1024;
  }

  // set box(LazyBox<Uint8List> value) {
  //   if (value != _box) {
  //     _box = value;
  //   }
  // }

  @HiveField(4)
  int order;
}
