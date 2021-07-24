import 'dart:io';
import 'dart:math';

import 'package:ikvpack/ikvpack.dart';

late IsolatePool pool;

void initIsolatePool() {
  //ODO - return pool back to normal
  pool = IsolatePool(max(Platform.numberOfProcessors - 1, 2));
  //pool = IsolatePool(4);
  pool.start();
}
