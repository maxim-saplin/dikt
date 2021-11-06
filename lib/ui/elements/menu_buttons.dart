import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dikt/ui/routes.dart';
import 'package:dikt/ui/screens/settings.dart';
import 'package:dikt/common/simple_simple_dialog.dart';
import 'package:dikt/ui/screens/dictionaries.dart';
import 'package:dikt/models/masterDictionary.dart';

class TopButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var dictionary = Provider.of<MasterDictionary>(context);
    return !dictionary.isFullyLoaded
        ? Text('')
        : SafeArea(
            minimum: const EdgeInsets.all(20),
            child: Align(alignment: Alignment.topRight, child: MenuButtons()));
  }
}

class MenuButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
              icon: Icon(Icons.view_list_rounded, size: 30),
              onPressed: () {
                showDialog(
                    context: context,
                    barrierColor: !kIsWeb ? Colors.transparent : Colors.black54,
                    routeSettings:
                        RouteSettings(name: Routes.dictionariesOffline),
                    builder: (BuildContext context) {
                      return SimpleSimpleDialog(
                          maxWidth: 800,
                          alignment: Alignment.center,
                          children: [Dictionaries(true)]);
                    });
              }),
          IconButton(
            icon: Icon(
              Icons.space_dashboard_rounded,
              size: 30,
            ),
            onPressed: () {
              showDialog(
                  context: context,
                  barrierColor: !kIsWeb ? Colors.transparent : Colors.black54,
                  routeSettings: RouteSettings(name: '/settings'),
                  builder: (BuildContext context) {
                    return SimpleSimpleDialog(
                        maxWidth: 320,
                        alignment: Alignment.center,
                        children: [Settings()]);
                  });
            },
          )
        ]);
  }
}
