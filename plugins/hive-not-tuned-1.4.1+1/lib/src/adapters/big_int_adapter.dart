import 'package:hive_not_tuned/hive_not_tuned.dart';

/// Adapter for BigInt
class BigIntAdapter extends TypeAdapter<BigInt> {
  @override
  final typeId = 17;

  @override
  BigInt read(BinaryReader reader) {
    var len = reader.readByte();
    var intStr = reader.readString(len);
    return BigInt.parse(intStr);
  }

  @override
  void write(BinaryWriter writer, BigInt obj) {
    var intStr = obj.toString();
    writer.writeByte(intStr.length);
    writer.writeString(intStr, writeByteCount: false);
  }
}
