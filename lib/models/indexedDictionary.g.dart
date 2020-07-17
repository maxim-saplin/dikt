// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'indexedDictionary.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IndexedDictionaryAdapter extends TypeAdapter<IndexedDictionary> {
  @override
  final typeId = 0;

  @override
  IndexedDictionary read(BinaryReader reader) {
    var numOfFields = reader.readByte();
    var fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IndexedDictionary()
      ..name = fields[0] as String
      ..enabled = fields[1] as bool
      ..boxName = fields[2] as String
      ..isReadyToUse = fields[3] as bool
      ..order = fields[4] as int;
  }

  @override
  void write(BinaryWriter writer, IndexedDictionary obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.enabled)
      ..writeByte(2)
      ..write(obj.boxName)
      ..writeByte(3)
      ..write(obj.isReadyToUse)
      ..writeByte(4)
      ..write(obj.order);
  }
}
