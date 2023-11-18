import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:provider/provider.dart';

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

  const Dictionaries({super.key, this.offline = false});

  @override
  Widget build(BuildContext context) {
    if (!toastShown) {
      Timer(const Duration(seconds: 1), () {
        try {
          showToast('Tap and hold to move'.i18n,
              context: context,
              animation: StyledToastAnimation.fade,
              reverseAnimation: StyledToastAnimation.fade);
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

    var manager = Provider.of<DictionaryManager>(context, listen: true);

    return PopScope(
        canPop: !manager.isRunning,
        // onWillPop: () async {
        //   var manager = Provider.of<DictionaryManager>(context, listen: false);
        //   if (manager.isRunning) {
        //     return false;
        //   }
        //   return true;
        // },
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
    super.key,
  });

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
