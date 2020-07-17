import 'package:hive/hive.dart';
import 'dart:typed_data';

part 'indexedDictionary.g.dart';

@HiveType(typeId: 0)
class IndexedDictionary extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  bool enabled;
  @HiveField(2)
  String boxName;
  @HiveField(3)
  bool
      isReadyToUse; //e.g. indexing can fail in the process, created though not complete box must be deleted
  bool isError;
  LazyBox<Uint8List> get box {
    return Hive.lazyBox(boxName);
  }

  @HiveField(4)
  int order;
}
