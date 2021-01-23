import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../models/dictionaryManager.dart';
import '../../common/i18n.dart';
import '../../models/onlineDictionaries.dart';
import '../screens/onlineDictionaries.dart';
import 'offlineDictionaries.dart';

class _SwitchedToOnline {
  bool yes = false;
}

class Dictionaries extends HookWidget {
  static bool toastShown = false;
  final bool _offline;

  Dictionaries(bool offline) : _offline = offline;

  @override
  Widget build(BuildContext context) {
    if (!toastShown) {
      var fToast = FToast();
      Timer(
          Duration(seconds: 1),
          () => fToast.showToast(
              child: Container(
                child: Text('Tap and hold to move'.i18n),
                color: Colors.grey,
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              ),
              toastDuration: Duration(seconds: 3)));
      toastShown = true;
    }

    final switchedToOnline = useMemoized(() => _SwitchedToOnline());

    if (!_offline)
      switchedToOnline.yes = false;
    else {
      if (!switchedToOnline.yes) {
        Provider.of<OnlineDictionaryManager>(context)?.cleanUp();
        switchedToOnline.yes = true;
      }
    }

    return new WillPopScope(
        onWillPop: () async {
          var manager = Provider.of<DictionaryManager>(context, listen: false);
          if (manager.isRunning) {
            return false;
          }
          return true;
        },
        child: Stack(children: [
          Title(),
          Padding(
              padding: EdgeInsets.fromLTRB(12, 50, 12, 12),
              child: //Text('TEST')
                  _offline ? OfflineDictionaries() : OnlineDictionaries())
        ]));
  }
}

class Title extends StatelessWidget {
  const Title({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var manager = Provider.of<DictionaryManager>(context, listen: true);
    return Container(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
        height: 50.0,
        child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dictionaries'.i18n,
                style: Theme.of(context).textTheme.headline6,
              ),
              Text(' ' + manager.totalDictionaries.toString(),
                  style: Theme.of(context).textTheme.overline)
            ]));
  }
}
