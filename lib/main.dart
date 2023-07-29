import 'dart:async';

import 'package:ambilytics/ambilytics.dart';
import 'package:dikt/ui/elements/word_articles.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:i18n_extension/i18n_widget.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:dikt/common/preferences_singleton.dart';
import 'package:dikt/models/online_dictionaries.dart';
import 'package:dikt/ui/themes.dart';
import 'package:ambilytics/ambilytics.dart' as ambilytics;

import 'firebase_options.dart';
import 'models/master_dictionary.dart';
import './models/preferences.dart';
import 'ui/screens/article.dart';
import 'ui/screens/home.dart';
import './models/history.dart';
import 'models/dictionary_manager.dart';
import 'common/isolate_pool.dart';
import 'models/online_dictionaries_fakes.dart';
import 'ui/routes.dart';

String _error = '';

// On desktop it is possible to override the path (via arg) where the app stores it's files
void main(List<String> arguments) async {
  try {
    if (!kIsWeb) initIsolatePool();
    WidgetsFlutterBinding.ensureInitialized();
    await PreferencesSingleton.init();

    await ambilytics.initAnalytics(
        disableAnalytics: !Preferences().isAnalyticsEnabled,
        firebaseOptions: DefaultFirebaseOptions.currentPlatform,
        measurementId: measurementId,
        apiSecret: apiSecret);

    await DictionaryManager.init(arguments.isNotEmpty ? arguments[0] : null);
  } catch (e) {
    _error = e.toString();
  }

  //print(const String.fromEnvironment("testVal2", defaultValue: "NOT FOUND"));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  Scaffold _getScaffold(Widget child) {
    return Scaffold(
        //key: Routes.navigator,
        body: BackButtonHandler(child: child));
  }

  static double wideWidth = 600;

  @override
  Widget build(BuildContext context) {
    if (_error.isNotEmpty) {
      return MaterialApp(
          home: _getScaffold(Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Text('Error launching app. \n\n $_error'))))));
    }

    return MultiProvider(
        providers: [
          ChangeNotifierProvider<DictionaryManager>(
            create: (context) => DictionaryManager()
              ..addListener(() {
                WordArticlesCache.invalidateCache();
              }),
          ),
          ChangeNotifierProvider<OnlineDictionaryManager>(
              create: (context) => OnlineDictionaryManager(
                  FakeOnlineRepo(), OnlineToOfflineFake())
              //Provider.of<DictionaryManager>(context, listen: false)),
              ),
          ChangeNotifierProvider<Preferences>(
              create: (context) => Preferences()),
          ChangeNotifierProvider<History>(create: (context) {
            return History();
          }),
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
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: const [
                    Locale('en', ''),
                    Locale('be', ''),
                    Locale('ru', ''),
                  ],
                  navigatorKey: Routes.navigator,
                  navigatorObservers: [
                    Routes
                        .observer, // this one is needed for reliable current route identification via custom routing helpers
                    AmbilyticsObserver(routeFilter: ambilytics.anyRouteFilter)
                  ],
                  builder: (BuildContext context, Widget? child) {
                    // Invalidating cache here helps with dark/light theme switching and WordArticles not being broken
                    WordArticlesCache.invalidateCache();
                    Timer.run(() {
                      if (preferences.isLocaleInitialized) {
                        I18n.of(context).locale = preferences.locale;
                      } else {
                        preferences.locale = Localizations.localeOf(
                            context); // set to system default locale. Flutter picks one of supported locales is there's a match
                      }
                    });

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
                            child: _getScaffold(const Home()),
                            type: PageTransitionType.fade);
                      case Routes.article:

                        // return PageRouteBuilder(
                        //   pageBuilder: (BuildContext context,
                        //       Animation<double> animation1,
                        //       Animation<double> animation2) {
                        //     return _getScaffold(Content(
                        //         word: (settings.arguments ?? '') as String));
                        //   },
                        //   transitionDuration: Duration.zero,
                        //   reverseTransitionDuration: Duration.zero,
                        // );

                        return PageTransition(
                            settings: settings,
                            duration: const Duration(milliseconds: 250),
                            child: _getScaffold(Content(
                                word: (settings.arguments ?? '') as String)),
                            type: PageTransitionType.fade);

                      // var w = _getScaffold(Content(
                      //     word: (settings.arguments ?? '') as String));

                      // return UnanimatedPageRoute(builder: (context) => w);
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
}

class UnanimatedPageRoute<T> extends MaterialPageRoute<T> {
  UnanimatedPageRoute({
    required Widget Function(BuildContext) builder,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) : super(
          builder: builder,
          settings: settings,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
