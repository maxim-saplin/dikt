import 'package:dikt/models/dictionary.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dikt/models/preferences.dart';
import 'package:dikt/models/history.dart';

class Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var model = Provider.of<Preferences>(context);
    return SingleChildScrollView(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Theme'),
            OutlineButton(
              child: Text(model.theme),
              onPressed: () => model.circleThemeMode(),
            )
          ],
        ),
        SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Language'),
          OutlineButton(
            child: Text('EN'),
            onPressed: () {},
          )
        ]),
        SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          OutlineButton(
            child: Text('Clear History'),
            onPressed: () {
              Provider.of<History>(context, listen: false).clear();
              // Lazy implementing propper update, using workaround
              Provider.of<Dictionary>(context, listen: false).notify();
            },
          )
        ]),
      ],
    ));
  }
}
