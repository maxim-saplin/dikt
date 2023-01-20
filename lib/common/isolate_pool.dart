import 'dart:io';
import 'dart:math';

import 'package:isolate_pool_2/isolate_pool_2.dart';

IsolatePool? pool;

void initIsolatePool() {
  // There's a bug when there're many isolates created and activity is hidden, resuming to the activity shows it frozen
  // https://github.com/dart-lang/sdk/issues/47672
  pool = IsolatePool(max(Platform.numberOfProcessors - 1,
      2)); // more cores lead to faster dictionary loads yet slower lookups
  // ODO - return pool back to normal
  // pool = IsolatePool(1);
  pool!.start();
}
