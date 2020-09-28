import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';

const filePath = './En-En-WordNet3-00.json';
const outputExtension = 'bundle';

void main(List<String> arguments) async {
  bundleJson(filePath);
  //_test();
}

void bundleJson(String fileName, [bool verify = true]) async {
  var input = File(fileName);
  var output = File(fileName + '.' + outputExtension);
  var jsonString = await input.readAsString();
  Map mm = json.decode(jsonString);
  var m = mm.cast<String, String>();
  var comp = zlib(m);

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
    var m = await readFile(output.path);
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

Future<Map<String, Uint8List>> readByteData(ByteData file) async {
  var m = Map<String, Uint8List>();

  var position = 0;

  var count = file.getInt32(position);
  position += 4;

  while (position < file.lengthInBytes - 1) {}

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

void _test() async {
  var f = File('./En-En-WordNet3-00.json');
  var s = await f.readAsString();
  test(s);
}

void test(String jsonString) {
  Map mm = json.decode(jsonString);
  var m = mm.cast<String, String>();
  for (var i = 0; i < 3; i++) {
    var comp = gzip(m);
    gzipDecomp(comp);
    comp = zlib(m);
    zlibDecomp(comp);
    //bzip2(m);
    print('\n');
  }
}

class _CompUncomp {
  var uncompressed = 0;
  var compressed = 0;
  Map<String, Uint8List> m = {};
}

Map<String, Uint8List> zlib(Map<String, String> m) {
  var comp = (Map<String, String> m) {
    var cu = _CompUncomp();
    var enc = ZLibEncoder();
    for (var e in m.entries) {
      var bytes = utf8.encode(e.value);
      cu.uncompressed += bytes.length;
      var gzipBytes = enc.encode(bytes);
      var b = Uint8List.fromList(gzipBytes);
      cu.compressed += b.length;
      cu.m[e.key] = b;
    }
    return cu;
  };

  return _common(m, 'ZLib', comp);
}

void zlibDecomp(Map<String, Uint8List> m) {
  var sw = Stopwatch();
  sw.start();
  var dec = ZLibDecoder();
  for (var e in m.entries) {
    var b = Uint8List.fromList(e.value);
    var bytes = dec.decodeBytes(b);
  }
  sw.stop();
  print(
      'ZLib decoding: ' + sw.elapsedMilliseconds.toStringAsFixed(2) + ' (ms)');
}

Map<String, Uint8List> gzip(Map<String, String> m) {
  var func = (Map<String, String> m) {
    var cu = _CompUncomp();
    var enc = GZipEncoder();
    for (var e in m.entries) {
      var bytes = utf8.encode(e.value);
      cu.uncompressed += bytes.length;
      var gzipBytes = enc.encode(bytes);
      var b = Uint8List.fromList(gzipBytes);
      cu.compressed += b.length;
      cu.m[e.key] = b;
    }
    return cu;
  };

  return _common(m, 'GZIP', func);
}

void gzipDecomp(Map<String, Uint8List> m) {
  var sw = Stopwatch();
  sw.start();
  var dec = GZipDecoder();
  for (var e in m.entries) {
    var b = Uint8List.fromList(e.value);
    var bytes = dec.decodeBytes(b);
  }
  sw.stop();
  print(
      'GZip decoding: ' + sw.elapsedMilliseconds.toStringAsFixed(2) + ' (ms)');
}

Map<String, Uint8List> bzip2(Map<String, String> m) {
  var func = (Map<String, String> m) {
    var cu = _CompUncomp();
    var enc = BZip2Encoder();
    for (var e in m.entries) {
      var bytes = utf8.encode(e.value);
      cu.uncompressed += bytes.length;
      var gzipBytes = enc.encode(bytes);
      var b = Uint8List.fromList(gzipBytes);
      cu.compressed += b.length;
      cu.m[e.key] = b;
    }
    return cu;
  };

  return _common(m, 'BZip2', func);
}

Map<String, Uint8List> _common(Map<String, String> m, String name,
    _CompUncomp Function(Map<String, String> m) func) {
  var sw = Stopwatch();
  sw.start();

  var cu = func(m);

  sw.stop();

  print(name + ': ' + sw.elapsedMilliseconds.toStringAsFixed(2) + '(ms)');
  print(' Uncompressed/Compressed:');
  print(' ' +
      (cu.uncompressed / 1024 / 1024).toStringAsFixed(2) +
      'Mb / ' +
      (cu.compressed / 1024 / 1024).toStringAsFixed(2) +
      'Mb');
  print(
      ' ' + (cu.uncompressed / cu.compressed).toStringAsFixed(2) + ' - ratio');

  return cu.m;
}
