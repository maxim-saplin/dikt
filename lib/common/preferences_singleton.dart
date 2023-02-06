import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class PreferencesSingleton {
  static late SharedPreferences sp;

  static Future<void> init([SharedPreferences? mockInstance]) async {
    if (mockInstance != null) {
      sp = mockInstance;
    } else {
      WidgetsFlutterBinding.ensureInitialized();
      sp = await SharedPreferences.getInstance();
    }
  }

  static const String _twoPaneRatioParam = 'twoPaneRatioParam';

  static double get twoPaneRatio {
    double? v;
    v = PreferencesSingleton.sp.getDouble(_twoPaneRatioParam);

    if (v == null) {
      return 0.35;
    }

    return v;
  }

  static set twoPaneRatio(double value) {
    PreferencesSingleton.sp.setDouble(_twoPaneRatioParam, value);
  }
}
