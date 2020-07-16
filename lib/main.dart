import 'package:dikt/common/preferencesSingleton.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dikt/models/masterDictionary.dart';
import 'package:dikt/models/preferences.dart';
import 'package:dikt/screens/lookup.dart';
import 'package:dikt/models/history.dart';
import 'package:flutter/services.dart';
import 'models/dictionaryManager.dart';

void main() async {
  await PreferencesSingleton.init();
  await DictionaryManager.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<DictionaryManager>(
            create: (context) => DictionaryManager(),
          ),
          ChangeNotifierProvider<Preferences>(
            create: (context) => Preferences(),
          ),
          Provider(create: (context) => History()),
          ChangeNotifierProxyProvider<DictionaryManager, MasterDictionary>(
              create: (context) => MasterDictionary(),
              update: (context, manager, master) {
                master.dictionaryManager = manager;
                master.init();
                return master;
              }),
        ],
        child: Consumer<Preferences>(
            builder: (context, preferences, child) => MaterialApp(
                  title: 'dikt',
                  initialRoute: '/',
                  routes: {
                    '/': (context) {
                      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
                        systemNavigationBarColor: Theme.of(context)
                            .canvasColor, // navigation bar color
                      ));
                      return Lookup();
                    },
                  },
                  themeMode: preferences.themeMode,
                  theme: lightTheme,
                  darkTheme: darkTheme,
                )));
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
