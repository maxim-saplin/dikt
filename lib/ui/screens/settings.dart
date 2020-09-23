import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/i18n.dart';
import '../../models/preferences.dart';
import '../../models/history.dart';
import '../../models/masterDictionary.dart';

class Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var model = Provider.of<Preferences>(context);
    return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              children: [
                Container(
                    height: 50.0,
                    child: Text(
                      'Settings'.i18n,
                      style: Theme.of(context).textTheme.headline6,
                    ))
              ],
            ),
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
            Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlineButton(
                    child: Text('Clear History'.i18n),
                    onPressed: () {
                      Provider.of<History>(context, listen: false).clear();
                      // Lazy implementing propper update, using workaround
                      Provider.of<MasterDictionary>(context, listen: false)
                          .notify();
                    },
                  )
                ]),
          ],
        ));
  }
}
