import 'dart:async';

class Debounce {
  Timer debounceTimer;

  void debounce(Function f, int milliseconds) {
    debounceTimer?.cancel();
    debounceTimer = Timer(Duration(milliseconds: milliseconds), f);
  }
}
