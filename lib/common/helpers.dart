import 'dart:async';

class Debounce {
  Timer? debounceTimer;

  void debounce(Function f, int milliseconds) {
    debounceTimer?.cancel();
    debounceTimer =
        Timer(Duration(milliseconds: milliseconds), f as void Function());
  }
}

class Tuple<T, U> {
  final T value1;
  final U value2;

  Tuple(this.value1, this.value2);
}
