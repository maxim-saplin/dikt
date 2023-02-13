import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dikt/ui/routes.dart';
import 'package:dikt/ui/screens/settings.dart';
import 'package:dikt/models/master_dictionary.dart';

class TopButtons extends StatelessWidget {
  const TopButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var dictionary = Provider.of<MasterDictionary>(context);
    return !dictionary.isFullyLoaded
        ? const Text('')
        : const Align(alignment: Alignment.topRight, child: MenuButtons());
  }
}

class MenuButtons extends StatelessWidget {
  const MenuButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: defaultTargetPlatform == TargetPlatform.macOS ||
                defaultTargetPlatform == TargetPlatform.linux ||
                defaultTargetPlatform == TargetPlatform.windows
            ? const EdgeInsets.only(
                top: 20,
                right: 30,
              )
            : EdgeInsets.zero,
        child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Semantics(
                  tooltip: 'Show dictionaries',
                  child: IconButton(
                      icon: const Icon(Icons.view_list_rounded, size: 30),
                      onPressed: () {
                        Routes.showOfflineDictionaries();
                      })),
              Semantics(
                  tooltip: 'Show settings',
                  child: IconButton(
                    icon: const Icon(
                      Icons.space_dashboard_rounded,
                      size: 30,
                    ),
                    onPressed: () {
                      showDialog(
                          context: context,
                          barrierColor:
                              !kIsWeb ? Colors.transparent : Colors.black54,
                          routeSettings: const RouteSettings(name: '/settings'),
                          builder: (BuildContext context) {
                            return blurBackground(const SimpleDialog(
                                //maxWidth: 320,
                                alignment: Alignment.center,
                                children: [Settings()]));
                          });
                    },
                  ))
            ]));
  }
}
