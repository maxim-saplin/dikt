import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class PreferencesSingleton {
  static SharedPreferences sp;

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    sp = await SharedPreferences.getInstance();
    return sp;
  }
}
