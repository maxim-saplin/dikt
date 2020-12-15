import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_not_tuned/hive_not_tuned.dart' as HNT;

void main() {
  test('Tuned HiveDB loads faster', () async {
    var ms = await measureAvgMs(() async {
      Hive.init('./test/data');
      var b =
          await Hive.openLazyBox<Uint8List>('dik_enenwordnet3', readOnly: true);
      return b.keys.length;
    }, teardown: () async {
      await Hive.close();
    });

    print('Tuned: ' + ms.toString());

    var ms2 = await measureAvgMs(() async {
      HNT.Hive.init('./test/data');
      var b = await HNT.Hive.openLazyBox<Uint8List>('dik_enenwordnet3');
      return b.keys.length;
    }, teardown: () async {
      await HNT.Hive.close();
    });

    print('Not tuned: ' + ms2.toString());
    print('Time decrease: ${((ms2 - ms) / ms2 * 100).toStringAsFixed(1)}%');
    expect(ms < ms2, true);
  });
}

Future<double> measureAvgMs(Future<int> Function() body,
    {Function setup, Future Function() teardown, int times = 5}) async {
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

  return sw.elapsedMilliseconds / times;
}
