import 'package:flutter/material.dart';
import 'package:dikt/common/preferences_singleton.dart';

bool widgetTestMode = false;

class Preferences extends ChangeNotifier {
  static const String _themeModeParam = 'themeMode';
  ThemeMode? _themeMode;

  ThemeMode? get themeMode {
    if (_themeMode == null) {
      int? v;
      try {
        v = PreferencesSingleton.sp.getInt(_themeModeParam);
      } catch (_) {}
      if (v == null) {
        _themeMode = ThemeMode.system;
      } else {
        _themeMode = ThemeMode.values[v];
      }
    }
    return _themeMode;
  }

  set themeMode(ThemeMode? value) {
    if (value != _themeMode) {
      _themeMode = value;
      PreferencesSingleton.sp.setInt(_themeModeParam, value!.index);
      notifyListeners();
    }
  }

  String get theme {
    if (themeMode == ThemeMode.dark) return 'Dark';
    if (themeMode == ThemeMode.light) return 'Light';
    return 'System';
  }

  void circleThemeMode() {
    if (themeMode == ThemeMode.dark) {
      themeMode = ThemeMode.light;
    } else if (themeMode == ThemeMode.light) {
      themeMode = ThemeMode.system;
    } else {
      themeMode = ThemeMode.dark;
    }
  }

  static const String _localeParam = 'locale';
  Locale? _locale;

  Locale? get locale {
    if (_locale == null) {
      var v = PreferencesSingleton.sp.getString(_localeParam);
      if (v == null) {
        _locale = const Locale('en', '');
      } else {
        _locale = Locale(v, '');
      }
    }
    return _locale;
  }

  bool get isLocaleInitialized {
    return PreferencesSingleton.sp.containsKey(_localeParam);
  }

  set locale(Locale? value) {
    if (value?.languageCode != _locale?.languageCode) {
      _locale = value;
      PreferencesSingleton.sp.setString(_localeParam, value!.languageCode);
      notifyListeners();
    }
  }

  void circleLocale() {
    if (_locale!.languageCode == 'en') {
      locale = const Locale('be', '');
    } else if (_locale!.languageCode == 'be') {
      locale = const Locale('ru', '');
    } else {
      locale = const Locale('en', '');
    }
  }

  static const String _analyticsParam = 'analytics';
  bool? _isAnalyticsEnabled;

  bool? get isAnalyticsEnabled {
    if (_isAnalyticsEnabled == null) {
      bool? v;
      try {
        v = PreferencesSingleton.sp.getBool(_analyticsParam);
      } catch (_) {}
      if (v == null) {
        _isAnalyticsEnabled = true;
      } else {
        _isAnalyticsEnabled = v;
      }
    }
    return _isAnalyticsEnabled;
  }

  set isAnalyticsEnabled(bool? value) {
    if (value != _isAnalyticsEnabled) {
      _isAnalyticsEnabled = value;
      PreferencesSingleton.sp.setBool(_analyticsParam, value!);
      notifyListeners();
    }
  }

  void circleAnalyticsEnabled() {
    isAnalyticsEnabled = !isAnalyticsEnabled!;
  }

  bool get showPerfCounters => !widgetTestMode;
}
