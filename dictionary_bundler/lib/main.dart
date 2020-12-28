import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'benchmark.dart';

const filePath =
    '/private/var/user/Dropbox/Projects/dikt_misc/dic/dictionaries2/1/RuEnUniversal.json'; //'./En-En-WordNet3-00.json';
const outputExtension = 'bundle';

void main(List<String> arguments) async {
  //bundleJson(filePath);
  testOnFile();
}

void bundleJson(String fileName, [bool verify = true]) async {
  var input = File(fileName);
  var output = File(fileName + '.' + outputExtension);
  var jsonString = await input.readAsString();
  Map mm = json.decode(jsonString);
  var m = mm.cast<String, String>();
  var comp = zlib(m, 6);

  print('Writing ${m.length} entries to ${output.path}');
  await output.create();
  var raf = await output.open(mode: FileMode.write);

  var bd = ByteData(4);
  bd.setInt32(0, m.length);
  raf.writeFromSync(bd.buffer.asUint8List());

  for (var e in comp.entries) {
    var bytes = utf8.encode(e.key);
    bd = ByteData(4);
    bd.setInt32(0, bytes.length);
    raf.writeFromSync(bd.buffer.asUint8List());
    raf.writeFromSync(bytes);

    bd = ByteData(4);
    bd.setInt32(0, e.value.length);
    raf.writeFromSync(bd.buffer.asUint8List());
    raf.writeFromSync(e.value);
  }
  raf.close();
  if (verify) {
    print('Veryfing ${output.path} ...');
    //var m = await readFile(output.path);
    var m = await readFileViaByteData(output.path);
    if (comp.length != m.length) {
      print('Wrong length. Saved ${comp.length}, read ${m.length}');
    } else {
      for (var k in m.keys) {
        if (m[k].length != comp[k].length) {
          print('Wrong values for key "${k}"');
          break;
        }
      }
    }
  }

  print('DONE');
}

Future<Map<String, Uint8List>> readFileViaByteData(String fileName) async {
  var f = File(fileName);
  var b = f.readAsBytesSync();
  var m = readByteData(b.buffer.asByteData());
  return m;
}

Map<String, Uint8List> readByteData(ByteData file) {
  var m = Map<String, Uint8List>();

  var position = 0;

  var count = file.getInt32(position);
  position += 4;
  print(count);
  var counter = 0;

  while (position < file.lengthInBytes - 1 && counter < count) {
    counter++;

    var length = file.getInt32(position);
    position += 4;
    var bytes = file.buffer.asUint8List(position, length);
    var key = utf8.decode(bytes);
    position += length;

    length = file.getInt32(position);
    position += 4;
    bytes = file.buffer.asUint8List(position, length);
    position += length;

    m[key] = bytes;
  }

  return m;
}

int _readInt32(RandomAccessFile raf) {
  var int32 = Uint8List(4);
  if (raf.readIntoSync(int32) <= 0) return -1;
  var bd = ByteData.sublistView(int32);
  var val = bd.getInt32(0);
  return val;
}

Uint8List _readIntList(RandomAccessFile raf, int count) {
  var bytes = Uint8List(count);
  if (raf.readIntoSync(bytes) <= 0) return null;

  return bytes;
}

Future<Map<String, Uint8List>> readFile(String fileName) async {
  var f = File(fileName);
  var raf = await f.open();

  var count = _readInt32(raf);

  print('Reading ${count} entries from file ${fileName}');

  var m = Map<String, Uint8List>();

  while (true) {
    var length = _readInt32(raf);
    if (length < 0) break;
    var bytes = _readIntList(raf, length);
    if (bytes == null) break;
    var key = utf8.decode(bytes);
    length = _readInt32(raf);
    if (length < 0) break;
    var value = _readIntList(raf, length);
    m[key] = value;
  }

  return m;
}
