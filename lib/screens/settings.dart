import 'package:dikt/models/masterDictionary.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dikt/models/preferences.dart';
import 'package:dikt/models/history.dart';

import '../common/i18n.dart';

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
            Text('Theme'.i18n),
            OutlineButton(
              child: Text(model.theme.i18n),
              onPressed: () => model.circleThemeMode(),
            )
          ],
        ),
        SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Language'.i18n),
          OutlineButton(
            child: Text(model.locale.languageCode.i18n),
            onPressed: () => model.circleLocale(),
          )
        ]),
        SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Analytics'.i18n),
          OutlineButton(
            child: Text(model.isAnalyticsEnabled ? 'On'.i18n : 'Off'.i18n),
            onPressed: () => model.circleAnalyticsEnabled(),
          )
        ]),
        SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          OutlineButton(
            child: Text('Clear History'.i18n),
            onPressed: () {
              Provider.of<History>(context, listen: false).clear();
              // Lazy implementing propper update, using workaround
              Provider.of<MasterDictionary>(context, listen: false).notify();
            },
          )
        ]),
      ],
    ));
  }
}
