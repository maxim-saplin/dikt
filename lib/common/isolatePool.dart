import 'dart:io';
import 'dart:math';

import 'package:ikvpack/ikvpack.dart';

IsolatePool pool;

void initIsolatePool() {
  pool = IsolatePool(max(Platform.numberOfProcessors - 1, 2));
  pool.start();
}
