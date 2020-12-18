import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_not_tuned/hive_not_tuned.dart' as HNT;

void main() {
  void checkSorting(Iterable<dynamic> keys) {
    var keysFromHive = keys.toList();
    var sortedKeys = keysFromHive.toList()..sort();

    var mismatch = false;

    for (var i = 0; i < keysFromHive.length; i++) {
      if (keysFromHive[i] != sortedKeys[i]) {
        print('Mismatch at ${i}, "${keysFromHive[i]}" vs ${sortedKeys[i]}"');
        mismatch = true;
        break;
      }
    }
    expect(mismatch, false);
  }

  test('Tuned HiveDB doesn\'t break key order', () async {
    var b = await initHive();

    checkSorting(b.keys);
  });

  test('Not tuned HiveDB doesn\'t break key order', () async {
    var b = await initHNT();

    checkSorting(b.keys);
  });

  test('Tuned HiveDB iterating through keys is not slower', () async {
    var words = {'go', 'ze', 'be', 'fo', 'a', 'z'};

    const maxResults = 100;

    void getMatches(Iterable<dynamic> keys) {
      List<String> matches = [];
      for (var w in words) {
        int n = 0;
        for (var k in keys) {
          if (k.startsWith(w)) {
            n++;
            matches.add(k);
            if (n > maxResults) break;
          }
        }
        matches.clear();
      }
    }

    var b = await initHive();
    var ms = await measureAvgMs(() async {
      getMatches(b.keys);
      return b.keys.length;
    }, times: 10, microseconds: true);
    await closeHive();

    var b2 = await initHNT();
    var ms2 = await measureAvgMs(() async {
      getMatches(b2.keys);
      return b2.keys.length;
    }, times: 10, microseconds: true);
    await closeHNT();

    var percent = (1 - ms / ms2) * 100;

    print('Tuned (microsec): ${ms}, not-tuned: ${ms2} , ${percent}');

    expect(percent > -10, true);
  });

  test('Tuned HiveDB key lookup is not slower', () async {
    var words = {'go', 'ze', 'be', 'fo', 'a', 'z'};

    const maxResults = 100;

    List<List<String>> getMatches(Iterable<dynamic> keys) {
      List<List<String>> matches = [];

      for (var w in words) {
        int n = 0;
        List<String> s = [];
        for (var k in keys) {
          if (k.startsWith(w)) {
            n++;
            s.add(k);
            if (n > maxResults) break;
          }
        }
        matches.add(s);
      }

      return matches;
    }

    var b = await initHive();

    var matches = getMatches(b.keys);

    var ms = await measureAvgMs(() {
      for (var m in matches) {
        for (var w in m) {
          // ignore: unused_local_variable
          var value = b.get(w);
        }
      }
      return Future.delayed(Duration(seconds: 0), () => b.keys.length);
    }, times: 10, microseconds: true);
    await closeHive();

    var b2 = await initHNT();
    var ms2 = await measureAvgMs(() async {
      for (var m in matches) {
        for (var w in m) {
          // ignore: unused_local_variable
          var value = b2.get(w);
        }
      }
      return Future.delayed(Duration(seconds: 0), () => b2.keys.length);
    }, times: 10, microseconds: true);
    await closeHNT();

    var percent = (1 - ms / ms2) * 100;

    print('Tuned (microsec): ${ms}, not-tuned: ${ms2} , ${percent}');

    expect(percent > -10, true);
  });

  test('Tuned HiveDB loads faster', () async {
    var ms = await measureAvgMs(() async {
      var b = await initHive();
      return b.keys.length;
    }, teardown: () async {
      await closeHive();
    });

    print('Tuned: ' + ms.toString());

    var ms2 = await measureAvgMs(() async {
      HNT.LazyBox<Uint8List> b = await initHNT();
      return b.keys.length;
    }, teardown: () async {
      await closeHNT();
    });

    print('Not tuned: ' + ms2.toString());
    print('Time decrease: ${((ms2 - ms) / ms2 * 100).toStringAsFixed(1)}%');
    expect(ms < ms2, true);
  }, skip: true); // test can be slow, better skip in regular use
}

Future<HNT.LazyBox<Uint8List>> initHNT() async {
  HNT.Hive.init('./test/data');
  var b = await HNT.Hive.openLazyBox<Uint8List>('dik_enenwordnet3');
  return b;
}

void closeHNT() async {
  await HNT.Hive.close();
}

Future<LazyBox<Uint8List>> initHive() async {
  Hive.init('./test/data');
  var b = await Hive.openLazyBox<Uint8List>('dik_enenwordnet3', readOnly: true);
  return b;
}

void closeHive() async {
  await Hive.close();
}

Future<double> measureAvgMs(Future<int> Function() body,
    {Function setup,
    Future Function() teardown,
    int times = 5,
    bool microseconds = false}) async {
  var sw = Stopwatch();

  for (var i = -1; i < times; i++) {
    if (setup != null) setup();
    var t = -1;
    if (i >= 0) sw.start();
    t = await body();
    if (i >= 0) sw.stop;
    print(t);
    if (setup != null) await teardown();
  }

  if (microseconds) sw.elapsedMicroseconds / times;

  return sw.elapsedMilliseconds / times;
}
