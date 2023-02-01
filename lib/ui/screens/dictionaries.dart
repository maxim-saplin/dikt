import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../models/dictionary_manager.dart';
import '../../common/i18n.dart';
import '../../models/online_dictionaries.dart';
import 'online_dictionaries.dart';
import 'offline_dictionaries.dart';

class _SwitchedToOnline {
  bool yes = false;
}

class Dictionaries extends HookWidget {
  static bool toastShown = false;
  final bool offline;

  const Dictionaries({Key? key, this.offline = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!toastShown) {
      var fToast = FToast();
      Timer(const Duration(seconds: 1), () {
        try {
          fToast.showToast(
              child: Container(
                color: Colors.grey,
                padding:
                    const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: Text('Tap and hold to move'.i18n),
              ),
              toastDuration: const Duration(seconds: 3));
        } catch (_) {}
      });
      toastShown = true;
    }

    final switchedToOnline = useMemoized(() => _SwitchedToOnline());

    if (!offline) {
      switchedToOnline.yes = false;
    } else {
      if (!switchedToOnline.yes) {
        Provider.of<OnlineDictionaryManager>(context).cleanUp();
        switchedToOnline.yes = true;
      }
    }

    return WillPopScope(
        onWillPop: () async {
          var manager = Provider.of<DictionaryManager>(context, listen: false);
          if (manager.isRunning) {
            return false;
          }
          return true;
        },
        child: Stack(children: [
          const Title(),
          Padding(
              padding: const EdgeInsets.fromLTRB(12, 50, 12, 12),
              child: offline
                  ? const OfflineDictionaries()
                  : const OnlineDictionaries())
        ]));
  }
}

class Title extends StatelessWidget {
  const Title({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var manager = Provider.of<DictionaryManager>(context, listen: true);
    return Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        height: 50.0,
        child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dictionaries'.i18n,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(' ${manager.totalDictionaries}',
                  style: Theme.of(context).textTheme.labelSmall)
            ]));
  }
}
