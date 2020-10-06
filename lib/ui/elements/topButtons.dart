import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/settings.dart';
import '../../common/simpleSimpleDialog.dart';
import '../screens/dictionaries.dart';
import '../../models/masterDictionary.dart';

class TopButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var dictionary = Provider.of<MasterDictionary>(context);

    return !dictionary.isFullyLoaded
        ? Text('')
        : SafeArea(
            minimum: const EdgeInsets.all(20),
            child: Align(
                alignment: Alignment.topRight,
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  IconButton(
                      icon: Icon(Icons.dns, size: 30),
                      onPressed: () {
                        showDialog(
                            context: context,
                            barrierColor:
                                !kIsWeb ? Colors.transparent : Colors.black54,
                            routeSettings: RouteSettings(name: '/dictionaries'),
                            builder: (BuildContext context) {
                              return SimpleSimpleDialog(
                                  maxWidth: 500,
                                  title: Text('Dictionaries'),
                                  alignment: Alignment.center,
                                  children: [Dictionaries()]);
                            });
                      }),
                  IconButton(
                    icon: Icon(
                      Icons.apps,
                      size: 30,
                    ),
                    onPressed: () {
                      showDialog(
                          context: context,
                          barrierColor:
                              !kIsWeb ? Colors.transparent : Colors.black54,
                          routeSettings: RouteSettings(name: '/settings'),
                          builder: (BuildContext context) {
                            return SimpleSimpleDialog(
                                maxWidth: 320,
                                alignment: Alignment.center,
                                children: [Settings()]);
                          });
                    },
                  )
                ])));
  }
}
