import 'dart:io';
import 'dart:math';

import 'package:ikvpack/ikvpack.dart';

IsolatePool? pool;

void initIsolatePool() {
  // There's a bug when there're many isolates created and activity is hidden, resuming to the activity shows it frozen
  // https://github.com/dart-lang/sdk/issues/47672
  pool = IsolatePool(max(Platform.numberOfProcessors, 2));
  // ODO - return pool back to normal
  //pool = IsolatePool(2);
  pool!.start();
}
