@JS()

import 'dart:typed_data';

import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS()
external Object bulkInsert(
    dynamic db, List<String> keys, List<Uint8List> values);

@JS()
external void testArrays(List<String> key, List<Uint8List> values);

Future<void> toFuture(Object promise) {
  return promiseToFuture(promise);
}
