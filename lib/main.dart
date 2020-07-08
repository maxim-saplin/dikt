import 'package:dikt/common/preferencesSingleton.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dikt/models/dictionary.dart';
import 'package:dikt/models/preferences.dart';
import 'package:dikt/screens/lookup.dart';
import 'package:dikt/models/history.dart';

void main() async {
  await PreferencesSingleton.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<Dictionary>(
            create: (context) => Dictionary(),
          ),
          ChangeNotifierProvider<Preferences>(
            create: (context) => Preferences(),
          ),
          Provider(create: (context) => History()),
        ],
        child: Consumer<Preferences>(
          builder: (context, preferences, child) => MaterialApp(
            title: 'dikt',
            initialRoute: '/',
            routes: {
              '/': (context) => Lookup(),
            },
            themeMode: preferences.themeMode,
            theme: lightTheme,
            darkTheme: darkTheme,
          ),
        ));
  }

  final ThemeData lightTheme = ThemeData.light().copyWith(
      textTheme: TextTheme(
    button: TextStyle(
      fontSize: 18,
      fontFamily: 'Montserrat',
    ),
    headline6: TextStyle(
      fontSize: 20.0,
      color: Colors.black,
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.bold,
    ),
    // standard TextField()
    subtitle1: TextStyle(
      fontSize: 20.0,
      fontFamily: 'Montserrat',
      color: Colors.black,
    ),
    // standard Text()
    bodyText2: TextStyle(
        fontSize: 20.0, fontFamily: 'Montserrat', color: Colors.black),
    // italic Text()
    bodyText1: TextStyle(
        fontSize: 20.0,
        fontFamily: 'Montserrat',
        fontStyle: FontStyle.italic,
        color: Colors.black),
  ));

  final ThemeData darkTheme = ThemeData.dark().copyWith(
      textTheme: TextTheme(
    button: TextStyle(
      fontSize: 18,
      fontFamily: 'Montserrat',
    ),
    headline6: TextStyle(
      fontSize: 20.0,
      color: Colors.white,
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.bold,
    ),
    subtitle1: TextStyle(
      fontSize: 20.0,
      fontFamily: 'Montserrat',
      color: Colors.white,
    ),
    bodyText2: TextStyle(
        fontSize: 20.0, fontFamily: 'Montserrat', color: Colors.white),
  ));
}
