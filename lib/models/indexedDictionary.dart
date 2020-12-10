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
      isReadyToUse; //set to false before starting indexing and to true when done. E.g. if you reload page or close app while indexing it won't be ready
  // error while indexing
  bool isError = false;
  bool isLoaded = false;
  bool isBundled = false;

  //LazyBox<Uint8List> _box = null;

  LazyBox<Uint8List> get box {
    if (!Hive.isBoxOpen(boxName)) return null;
    return Hive.lazyBox<Uint8List>(boxName);
  }

  Future<LazyBox<Uint8List>> openBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      isLoaded = true;
      return await Hive.openLazyBox(boxName);
    }
    return box;
  }

  double get fileSizeMb {
    var file = File(box.path);
    return file.lengthSync() / 1024 / 1024;
  }

  @HiveField(4)
  int order;

  IndexedDictionary();

  IndexedDictionary.init(this.boxName, this.name, this.isEnabled);
}
