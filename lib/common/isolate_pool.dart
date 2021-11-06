import 'dart:io';
import 'dart:math';

import 'package:ikvpack/ikvpack.dart';

late IsolatePool pool;

void initIsolatePool() {
  //TODO - return pool back to normal
  //pool = IsolatePool(max(Platform.numberOfProcessors - 1, 2));
  pool = IsolatePool(2);
  pool.start();
}
