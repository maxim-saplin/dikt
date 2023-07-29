import 'dart:io';
import 'dart:math';

import 'package:isolate_pool_2/isolate_pool_2.dart';

IsolatePool? pool;

void initIsolatePool([int numberOfIsolates = 0]) {
  // There's a bug when there're many isolates created and activity is hidden, resuming to the activity shows it frozen
  // https://github.com/dart-lang/sdk/issues/47672
  pool = IsolatePool(numberOfIsolates > 0
      ? numberOfIsolates
      : max(Platform.numberOfProcessors - 1, 2));
  pool!.start();
}
