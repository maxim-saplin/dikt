import 'package:dikt/common/simpleSimpleDialog.dart';
import 'package:dikt/ui/screens/dictionaries.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Routes {
  static const String home = '/';
  static const String showArticleWide = '/lookupAndArticle';
  static const String showArticle = '/article';
  static const String dictionariesOnline = '/dictionariesOnline';
  static const String dictionariesOffline = '/dictionaries';

  static void showOfflineDictionaries(BuildContext context) {
    if (ModalRoute.of(context)!.settings.name == dictionariesOnline)
      Navigator.of(context).pop();

    showDialog(
        context: context,
        barrierColor: !kIsWeb ? Colors.transparent : Colors.black54,
        routeSettings: RouteSettings(name: Routes.dictionariesOffline),
        builder: (BuildContext context) {
          return SimpleSimpleDialog(
              maxWidth: 500,
              alignment: Alignment.center,
              children: [Dictionaries(true)]);
        });
  }

  static void showOnlineDictionaries(BuildContext context) {
    if (ModalRoute.of(context)!.settings.name == dictionariesOffline)
      Navigator.of(context).pop();

    showDialog(
        context: context,
        barrierColor: !kIsWeb ? Colors.transparent : Colors.black54,
        routeSettings: RouteSettings(name: Routes.dictionariesOnline),
        builder: (BuildContext context) {
          return SimpleSimpleDialog(
              maxWidth: 700,
              alignment: Alignment.center,
              children: [Dictionaries(false)]);
        });
  }
}
