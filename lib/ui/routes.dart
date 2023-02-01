import 'package:dikt/common/simple_simple_dialog.dart';
import 'package:dikt/ui/screens/dictionaries.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/history.dart';
import '../models/master_dictionary.dart';

class Routes {
  static final GlobalKey<NavigatorState> navigator =
      GlobalKey<NavigatorState>();

  static const String home = '/';
  static const String article = '/article';
  static const String dictionariesOnline = '/dictionariesOnline';
  static const String dictionariesOffline = '/dictionaries';

  static void showArticle(BuildContext context, String word) {
    var history = Provider.of<History>(context, listen: false);
    history.addWord(word);
    var dictionary = Provider.of<MasterDictionary>(context, listen: false);
    dictionary.selectedWord = word;

    Navigator.of(context).pushNamed(Routes.article, arguments: word);
  }

  static void showOfflineDictionaries(BuildContext context) {
    if (ModalRoute.of(context)!.settings.name == dictionariesOnline) {
      Navigator.of(context).pop();
    }

    showDialog(
        context: context,
        barrierColor: !kIsWeb ? Colors.transparent : Colors.black54,
        routeSettings: const RouteSettings(name: Routes.dictionariesOffline),
        builder: (BuildContext context) {
          return const SimpleSimpleDialog(
              maxWidth: 500,
              alignment: Alignment.center,
              children: [Dictionaries(offline: true)]);
        });
  }

  static void showOnlineDictionaries(BuildContext context) {
    if (ModalRoute.of(context)!.settings.name == dictionariesOffline) {
      Navigator.of(context).pop();
    }

    showDialog(
        context: context,
        barrierColor: !kIsWeb ? Colors.transparent : Colors.black54,
        routeSettings: const RouteSettings(name: Routes.dictionariesOnline),
        builder: (BuildContext context) {
          return const SimpleSimpleDialog(
              maxWidth: 700,
              alignment: Alignment.center,
              children: [Dictionaries(offline: false)]);
        });
  }
}
