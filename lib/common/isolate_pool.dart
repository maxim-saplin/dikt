import 'dart:io';
import 'dart:math';
import 'package:isolate_pool_2/isolate_pool_2.dart';

IsolatePool? _pool;

IsolatePool? get pool => _pool;

void initIsolatePool([int numberOfIsolates = 0]) {
  _pool = IsolatePool(numberOfIsolates > 0
      ? numberOfIsolates
      : max(Platform.numberOfProcessors - 1, 2));
  _pool!.start();
}
