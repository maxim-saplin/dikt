import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_not_tuned/hive_not_tuned.dart' as HNT;
import 'package:ikvpack/ikvpack.dart';

void main() {
  const ikvPath = 'test/data/dik_enenwordnet3.ikv';

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
  }, skip: true);

  test('Not tuned HiveDB doesn\'t break key order', () async {
    var b = await initHNT();

    checkSorting(b.keys);
  }, skip: true);

  test('IkvPack iterating through keys is not slower than tuned HiveDB ',
      () async {
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
      }
      matches.clear();
    }

    var ikv = IkvPack(ikvPath);
    var ms1 = await measureAvgMs(() async {
      getMatches(ikv.keys);
      return ikv.keys.length;
    }, times: 10, microseconds: true);
    await closeHive();

    var b2 = await initHive();
    var ms2 = await measureAvgMs(() async {
      getMatches(b2.keys);
      return b2.keys.length;
    }, times: 10, microseconds: true);
    await closeHive();

    var b3 = await initHNT();
    var ms3 = await measureAvgMs(() async {
      getMatches(b3.keys);
      return b3.keys.length;
    }, times: 10, microseconds: true);
    await closeHNT();

    var percent = (1 - ms1 / ms2) * 100;

    print(
        'IkvPack (microsec): ${ms1},  tuned: ${ms2} , ${percent.toStringAsFixed(1)}%');
    print('For reference, not-tuned: ${ms3}');

    expect(percent > -10, true);
  });

  test('IkvPack value lookup is not slower than tuned HiveDB', () async {
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

    var b2 = await initHive();
    var matches = getMatches(b2.keys);

    var ikv = IkvPack(ikvPath);
    var ms1 = await measureAvgMs(() {
      for (var m in matches) {
        for (var w in m) {
          // ignore: unused_local_variable
          var value = ikv.valueRawCompressed(w);
        }
      }
      return Future.delayed(Duration(seconds: 0), () => ikv.keys.length);
    }, times: 10, microseconds: true);

    var ms2 = await measureAvgMs(() {
      for (var m in matches) {
        for (var w in m) {
          // ignore: unused_local_variable
          var value = b2.get(w);
        }
      }
      return Future.delayed(Duration(seconds: 0), () => b2.keys.length);
    }, times: 10, microseconds: true);
    await closeHive();

    var b3 = await initHNT();
    var ms3 = await measureAvgMs(() async {
      for (var m in matches) {
        for (var w in m) {
          // ignore: unused_local_variable
          var value = b3.get(w);
        }
      }
      return Future.delayed(Duration(seconds: 0), () => b3.keys.length);
    }, times: 10, microseconds: true);
    await closeHNT();

    var percent = (1 - ms1 / ms2) * 100;

    print(
        'IkvPack (microsec): ${ms1}, tuned: ${ms2} , ${percent.toStringAsFixed(1)}%');
    print('For reference not-tuned: ${ms3}');

    expect(percent > -10, true);
  });

  test(
      'IkvPack.keysStartingWith() is faster than enumeraring keys in tuned HiveDB',
      () async {
    var words = {'go', 'ze', 'be', 'fo', 'a', 'z', 'fa', 'al', 'yo', 'c', 'de'};

    const maxResults = 200;

    void getMatchesIkv(IkvPack ikv) {
      List<String> matches = [];
      for (var w in words) {
        matches = ikv.keysStartingWith(w, maxResults);
      }
      matches.clear();
    }

    void getMatchesHive(Iterable<dynamic> keys) {
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
      }
      matches.clear();
    }

    var ikv = IkvPack(ikvPath);
    var ms1 = await measureAvgMs(() async {
      getMatchesIkv(ikv);
      return ikv.keys.length;
    }, times: 10, microseconds: true);
    await closeHive();

    var b2 = await initHive();
    var ms2 = await measureAvgMs(() async {
      getMatchesHive(b2.keys);
      return b2.keys.length;
    }, times: 10, microseconds: true);
    await closeHive();

    var percent = (1 - ms1 / ms2) * 100;

    print(
        'IkvPack (microsec): ${ms1},  tuned: ${ms2} , ${percent.toStringAsFixed(1)}%');

    expect(percent > -10, true);
  });

  test('IkvPack loads faster than tuned HiveDB ', () async {
    var ms = await measureAvgMs(() async {
      var b = await initHive();
      return b.keys.length;
    }, teardown: () async {
      await closeHive();
    });

    print('Tuned: ' + ms.toString());

    var ms2 = await measureAvgMs(() async {
      var ikv = IkvPack(ikvPath);
      return ikv.length;
    }, teardown: () async {});
    print('IkvPack: ' + ms2.toString());

    print('Time decrease: ${((ms - ms2) / ms * 100).toStringAsFixed(1)}%');
    expect(ms2 < ms, true);

    ms2 = await measureAvgMs(() async {
      HNT.LazyBox<Uint8List> b = await initHNT();
      return b.keys.length;
    }, teardown: () async {
      await closeHNT();
    });
    print('For refernce - not-tuned: ' + ms2.toString());
  }, skip: false); // test can be slow, better skip in regular use
}

Future<HNT.LazyBox<Uint8List>> initHNT() async {
  HNT.Hive.init('test/data');
  var b = await HNT.Hive.openLazyBox<Uint8List>('dik_enenwordnet3');
  return b;
}

void closeHNT() async {
  await HNT.Hive.close();
}

Future<LazyBox<Uint8List>> initHive() async {
  Hive.init('test/data');
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
