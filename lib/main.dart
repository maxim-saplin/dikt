import 'dart:async';
import 'dart:io' show Platform;

import 'package:double_back_to_close/double_back_to_close.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:i18n_extension/i18n_widget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:dikt/common/preferences_singleton.dart';
import 'package:dikt/models/online_dictionaries.dart';
import 'package:dikt/ui/themes.dart';

import 'models/master_dictionary.dart';
import './models/preferences.dart';
import './ui/screens/lookup.dart';
import 'ui/screens/lookup_and_article.dart';
import './models/history.dart';
import 'models/dictionary_manager.dart';
import 'common/analytics_observer.dart';
import './common/i18n.dart';
import 'common/isolate_pool.dart';
import 'models/online_dictionaries_fakes.dart';
import 'ui/routes.dart';

// Ad Blockers can break app due to exception in Firebase
bool _firebaseError = false;

void main() async {
  if (!kIsWeb) initIsolatePool();
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS)
      await Firebase.initializeApp();
  } catch (_) {
    _firebaseError = true;
  }
  await PreferencesSingleton.init();
  await DictionaryManager.init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  static FirebaseAnalytics? analytics;

  MyApp() {
    if (!_firebaseError && analytics == null) {
      try {
        analytics = FirebaseAnalytics.instance;
      } catch (_) {
        _firebaseError = true;
      }
    }
  }

  Scaffold _getScaffold(Widget child) {
    return Scaffold(
        body: DoubleBack(message: 'Tap back again to quit'.i18n, child: child));
  }

  static bool? _wide;
  static double wideWidth = 600;

  @override
  Widget build(BuildContext context) {
    var narrow = false;

    return MultiProvider(
        providers: [
          ChangeNotifierProvider<DictionaryManager>(
            create: (context) => DictionaryManager(),
          ),
          ChangeNotifierProvider<OnlineDictionaryManager>(
              create: (context) => OnlineDictionaryManager(
                  FakeOnlineRepo(), OnlineToOfflineFake())
              //Provider.of<DictionaryManager>(context, listen: false)),
              ),
          ChangeNotifierProvider<Preferences>(
            create: (context) => Preferences(),
          ),
          ChangeNotifierProvider(create: (context) => History()),
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
                  navigatorKey: Routes.navigator,
                  navigatorObservers: preferences.isAnalyticsEnabled! &&
                          !_firebaseError &&
                          (kIsWeb || Platform.isAndroid || Platform.isIOS)
                      ? [
                          AnalyticsObserver(analytics: analytics!),
                        ]
                      : [],
                  builder: (BuildContext context, Widget? child) {
                    Timer.run(() {
                      if (preferences.isLocaleInitialized) {
                        I18n.of(context).locale = preferences.locale;
                      } else {
                        preferences.locale = Localizations.localeOf(
                            context); // set to system default locale. Flutter picks one of supported locales is there's a match
                      }
                    });

                    narrow = MediaQuery.of(context).size.width < wideWidth;
                    resetNavHistoryIfWideModeChanged(!narrow);

                    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
                      systemNavigationBarColor: Theme.of(context)
                          .canvasColor, //  Android navigation bar color
                    ));

                    return MediaQuery(
                      data:
                          MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                      child: child!,
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
                      case Routes.showArticleWide:
                        return PageTransition(
                            settings: settings,
                            child: _getScaffold(LookupAndArticle(
                                settings.arguments as String?)),
                            type: PageTransitionType.fade);
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

  bool resetNavHistoryIfWideModeChanged(bool wide) {
    if (_wide == null) {
      _wide = wide; //MediaQuery.of(context).size.width >= wideWidth;
    } else {
      if ((_wide! && !wide) || (!_wide! && wide)) {
        _wide = !_wide!;
        Timer(Duration(microseconds: 10), () {
          Routes.navigator.currentState!.pushNamedAndRemoveUntil(Routes.home,
              (r) => r.settings.name == Routes.home || r.settings.name == null);
        });
        return true;
      }
    }
    return false;
  }
}
