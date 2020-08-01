import 'dart:async';

import 'package:dikt/common/preferencesSingleton.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:i18n_extension/i18n_widget.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import './models/masterDictionary.dart';
import './models/preferences.dart';
import './screens/lookup.dart';
import './models/history.dart';
import './models/dictionaryManager.dart';

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
          ChangeNotifierProvider<MasterDictionary>(create: (context) {
            var master = MasterDictionary();
            master.dictionaryManager =
                Provider.of<DictionaryManager>(context, listen: false);
            Timer(Duration.zero, () => master.init()); // run after UI is built
            return master;
          }),
        ],
        child: Consumer<Preferences>(
            builder: (context, preferences, child) => I18n(
                    child: MaterialApp(
                  localizationsDelegates: [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: [
                    const Locale('en', ''),
                    const Locale('be', ''),
                    const Locale('ru', ''),
                  ],
                  builder: (BuildContext context, Widget child) {
                    Timer.run(() {
                      if (preferences.isLocaleInitialized) {
                        I18n.of(context).locale = preferences.locale;
                      } else {
                        preferences.locale = Localizations.localeOf(
                            context); // set to system default locale. Flutter picks one of supported locales is there's a match
                      }
                    });
                    return MediaQuery(
                      data:
                          MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                      child: child,
                    );
                  },
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
                ))));
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
    subtitle2: TextStyle(
      fontSize: 16.0,
      fontFamily: 'Montserrat',
      fontStyle: FontStyle.italic,
      color: Colors.black.withAlpha(128),
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
    // Dictionary card, dictionary  name
    caption: TextStyle(
        fontSize: 17.0, fontFamily: 'Montserrat', color: Colors.black),
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
    subtitle2: TextStyle(
      fontSize: 16.0,
      fontFamily: 'Montserrat',
      fontStyle: FontStyle.italic,
      color: Colors.white.withAlpha(128),
    ),
    bodyText2: TextStyle(
        fontSize: 20.0, fontFamily: 'Montserrat', color: Colors.white),
    // Dictionary card, dictionary  name
    caption: TextStyle(
        fontSize: 17.0, fontFamily: 'Montserrat', color: Colors.white),
  ));
}
