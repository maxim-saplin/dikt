import 'dart:async';
import 'dart:io' show Platform;

import 'package:dikt/common/preferencesSingleton.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:i18n_extension/i18n_widget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:double_back_to_close_app/double_back_to_close_app.dart';

import './models/masterDictionary.dart';
import './models/preferences.dart';
import './ui/screens/lookup.dart';
import './ui/screens/lookupAndArticle.dart';
import './models/history.dart';
import './models/dictionaryManager.dart';
import './common/analyticsObserver.dart';
import './common/i18n.dart';
import 'ui/routes.dart';
//import 'package:dictionary_bundler/main.dart' show test;

// Ad Blockers can break app due to exception in Firebase
bool _firebaseError = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS)
      await Firebase.initializeApp();
  } catch (_) {
    _firebaseError = true;
  }
  await PreferencesSingleton.init();
  await DictionaryManager.init();

  // Testing archive efficiency on target platforms
  //var s =
  //    await rootBundle.loadString('assets/dictionaries/En-En-WordNet3-00.json');
  //test(s);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();
  static FirebaseAnalytics analytics;

  MyApp() {
    if (!_firebaseError && analytics == null) {
      try {
        analytics = FirebaseAnalytics();
      } catch (_) {
        _firebaseError = true;
      }
    }
  }

  Scaffold _getScaffold(Widget child) {
    return Scaffold(
        body: DoubleBackToCloseApp(
            snackBar: SnackBar(
              content: Text('Tap back again to quit'.i18n),
            ),
            child: child));
  }

  static bool _wide;
  static double wideWidth = 600;

  @override
  Widget build(BuildContext context) {
    var narrow = false;
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
                  navigatorKey: _navigator,
                  navigatorObservers: preferences.isAnalyticsEnabled &&
                          !_firebaseError &&
                          (kIsWeb || Platform.isAndroid || Platform.isIOS)
                      ? [
                          AnalyticsObserver(analytics: analytics),
                        ]
                      : [],
                  builder: (BuildContext context, Widget child) {
                    Timer.run(() {
                      if (preferences.isLocaleInitialized) {
                        I18n.of(context).locale = preferences.locale;
                      } else {
                        preferences.locale = Localizations.localeOf(
                            context); // set to system default locale. Flutter picks one of supported locales is there's a match
                      }
                    });

                    narrow = MediaQuery.of(context).size.width < wideWidth;
                    resetNavHistoryIfWideModeChanged(context, !narrow);

                    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
                      systemNavigationBarColor: Theme.of(context)
                          .canvasColor, //  Android navigation bar color
                    ));

                    return MediaQuery(
                      data:
                          MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                      child: child,
                    );
                  },
                  title: 'dikt',
                  onGenerateRoute: (settings) {
                    switch (settings.name) {
                      case Routes.home:
                        return PageTransition(
                            settings: settings,
                            child: narrow
                                ? _getScaffold(Lookup(true))
                                : _getScaffold(LookupAndArticle(null)),
                            type: PageTransitionType.fade);
                        break;
                      case Routes.showArticleWide:
                        return PageTransition(
                            settings: settings,
                            child: _getScaffold(
                                LookupAndArticle(settings.arguments)),
                            type: PageTransitionType.fade);
                        break;
                      default:
                        return null;
                    }
                  },
                  initialRoute: Routes.home,
                  themeMode: preferences.themeMode,
                  theme: lightTheme,
                  darkTheme: darkTheme,
                ))));
  }

  bool resetNavHistoryIfWideModeChanged(BuildContext context, bool wide) {
    if (_wide == null) {
      _wide = wide; //MediaQuery.of(context).size.width >= wideWidth;
    } else {
      if ((_wide && !wide) || (!_wide && wide)) {
        _wide = !_wide;
        Timer(Duration(microseconds: 10), () {
          _navigator.currentState.pushNamedAndRemoveUntil(Routes.home,
              (r) => r.settings.name == Routes.home || r.settings.name == null);
        });
        return true;
      }
    }
    return false;
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
      cardColor: Color.fromARGB(255, 50, 50, 50),
      scaffoldBackgroundColor: Color.fromARGB(255, 40, 40, 40),
      dialogBackgroundColor: Color.fromARGB(255, 50, 50, 50),
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
