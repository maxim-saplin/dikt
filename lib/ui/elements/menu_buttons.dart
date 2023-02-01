import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dikt/ui/routes.dart';
import 'package:dikt/ui/screens/settings.dart';
import 'package:dikt/ui/screens/dictionaries.dart';
import 'package:dikt/models/master_dictionary.dart';

class TopButtons extends StatelessWidget {
  const TopButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var dictionary = Provider.of<MasterDictionary>(context);
    return !dictionary.isFullyLoaded
        ? const Text('')
        : const SafeArea(
            minimum: EdgeInsets.all(20),
            child: Align(alignment: Alignment.topRight, child: MenuButtons()));
  }
}

class MenuButtons extends StatelessWidget {
  const MenuButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
              icon: const Icon(Icons.view_list_rounded, size: 30),
              onPressed: () {
                showDialog(
                    context: context,
                    barrierColor: !kIsWeb ? Colors.transparent : Colors.black54,
                    routeSettings:
                        const RouteSettings(name: Routes.dictionariesOffline),
                    builder: (BuildContext context) {
                      return const SimpleDialog(
                          //maxWidth: 800,
                          alignment: Alignment.center,
                          children: [Dictionaries(offline: true)]);
                    });
              }),
          IconButton(
            icon: const Icon(
              Icons.space_dashboard_rounded,
              size: 30,
            ),
            onPressed: () {
              showDialog(
                  context: context,
                  barrierColor: !kIsWeb ? Colors.transparent : Colors.black54,
                  routeSettings: const RouteSettings(name: '/settings'),
                  builder: (BuildContext context) {
                    return const SimpleDialog(
                        //maxWidth: 320,
                        alignment: Alignment.center,
                        children: [Settings()]);
                  });
            },
          )
        ]);
  }
}
