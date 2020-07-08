import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dikt/common/preferencesSingleton.dart';

class Preferences extends ChangeNotifier {
  ThemeMode _themeMode;

  ThemeMode get themeMode {
    if (_themeMode == null) {
      var v = PreferencesSingleton.sp.getInt(_themeModeParam);
      if (v == null) {
        _themeMode = ThemeMode.system;
      } else
        _themeMode = ThemeMode.values[v];
    }
    return _themeMode;
  }

  static const String _themeModeParam = 'themeMode';

  set themeMode(ThemeMode value) {
    if (value != _themeMode) {
      _themeMode = value;
      PreferencesSingleton.sp.setInt(_themeModeParam, value.index);
      notifyListeners();
    }
  }

  String get theme {
    if (themeMode == ThemeMode.dark) return 'Dark';
    if (themeMode == ThemeMode.light) return 'Light';
    return 'System';
  }

  void circleThemeMode() {
    if (themeMode == ThemeMode.dark)
      themeMode = ThemeMode.light;
    else if (themeMode == ThemeMode.light)
      themeMode = ThemeMode.system;
    else
      themeMode = ThemeMode.dark;
  }
}
