import 'dart:typed_data';
import 'dart:io';
import 'package:hive/hive.dart';

part 'indexedDictionary.g.dart';

@HiveType(typeId: 0)
class IndexedDictionary extends HiveObject {
  @HiveField(0)
  String boxName;
  @HiveField(1)
  bool isEnabled;
  @HiveField(2)
  String name;
  @HiveField(3)
  bool
      isReadyToUse; //e.g. indexing can fail in the process, created though not complete box must be deleted
  bool isError = false;
  bool isLoaded = false;

  //LazyBox<Uint8List> _box = null;

  LazyBox<Uint8List> get box {
    if (!Hive.isBoxOpen(boxName)) return null;
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

  @HiveField(4)
  int order;
}
