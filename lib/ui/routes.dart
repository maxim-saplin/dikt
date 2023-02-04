import 'package:dikt/ui/screens/dictionaries.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/history.dart';
import '../models/master_dictionary.dart';

class Routes {
  static BuildContext get currentContext => navigator.currentContext!;

  /// Using this global key to avoid mess with build contexts and potential "Looking up a deactivated widget's ancestor is unsafe" errors
  static final GlobalKey<NavigatorState> navigator =
      GlobalKey<NavigatorState>();

  static const String home = '/';
  static const String article = '/article';
  static const String dictionariesOnline = '/dictionariesOnline';
  static const String dictionariesOffline = '/dictionaries';

  static void showArticle(String word) {
    var route = ModalRoute.of(currentContext);
    if (route != null &&
        route.settings.name == article &&
        (route.settings.arguments as String) == word) {
      return;
    }

    var history = Provider.of<History>(currentContext, listen: false);
    history.addWord(word);
    var dictionary =
        Provider.of<MasterDictionary>(currentContext, listen: false);
    dictionary.selectedWord = word;

    var nowAtHome = route?.settings.name == home;

    Navigator.of(currentContext)
        .pushNamed(Routes.article, arguments: word)
        // Force reload when home page is reached
        .whenComplete(() {
      if (nowAtHome) {
        Navigator.of(currentContext).pushReplacementNamed(home);
      }
    });
  }

  static void showOfflineDictionaries() {
    // After goinf to navigator global key and using it's context this approach stopped returning route from the dialog
    //  if (ModalRoute.of(currentContext)?.settings.name == dictionariesOnline) {
    //     Navigator.of(currentContext).pop();
    //   }
    Navigator.of(currentContext).popUntil((route) {
      if (route.settings.name == dictionariesOnline) return false;
      return true;
    });

    showDialog(
        context: currentContext,
        barrierColor: !kIsWeb ? Colors.transparent : Colors.black54,
        routeSettings: const RouteSettings(name: Routes.dictionariesOffline),
        builder: (BuildContext context) {
          return const SimpleDialog(
              //maxWidth: 500,
              alignment: Alignment.center,
              children: [Dictionaries(offline: true)]);
        });
  }

  static void showOnlineDictionaries() {
    // After goinf to navigator global key and using it's context this approach stopped returning route from the dialog
    // if (ModalRoute.of(currentContext)?.settings.name == dictionariesOffline) {
    //   Navigator.of(currentContext).pop();
    // }

    Navigator.of(currentContext).popUntil((route) {
      if (route.settings.name == dictionariesOffline) return false;
      return true;
    });

    showDialog(
        context: currentContext,
        barrierColor: !kIsWeb ? Colors.transparent : Colors.black54,
        routeSettings: const RouteSettings(name: Routes.dictionariesOnline),
        builder: (BuildContext context) {
          return const SimpleDialog(
              alignment: Alignment.center,
              children: [Dictionaries(offline: false)]);
        });
  }
}
