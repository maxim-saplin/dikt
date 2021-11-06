import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../common/i18n.dart';
import '../../models/preferences.dart';
import '../../models/history.dart';
import '../../models/master_dictionary.dart';

class Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var model = Provider.of<Preferences>(context);
    var history = Provider.of<History>(context);
    return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
                height: 50.0,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings'.i18n,
                        style: Theme.of(context).textTheme.headline6,
                      ),
                      FutureBuilder(
                          future: PackageInfo.fromPlatform(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Text(
                                (snapshot.data as PackageInfo).version,
                                style: Theme.of(context).textTheme.overline,
                              );
                            }
                            ;
                            return SizedBox();
                          })
                    ])),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Theme'.i18n),
                OutlinedButton(
                  child: Text(model.theme.i18n),
                  onPressed: () => model.circleThemeMode(),
                )
              ],
            ),
            SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Language'.i18n),
              OutlinedButton(
                child: Text(model.locale!.languageCode.i18n),
                onPressed: () => model.circleLocale(),
              )
            ]),
            SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Analytics'.i18n),
              OutlinedButton(
                child: Text(model.isAnalyticsEnabled! ? 'On'.i18n : 'Off'.i18n),
                onPressed: () => model.circleAnalyticsEnabled(),
              )
            ]),
            SizedBox(height: 10),
            Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Opacity(
                      opacity: history.wordsCount > 0 ? 1 : 0.5,
                      child: OutlinedButton(
                        child: Text('Clear History'.i18n),
                        onPressed: () {
                          history.clear();
                          // Lazy implementing propper update, using workaround
                          Provider.of<MasterDictionary>(context, listen: false)
                              .notify();
                        },
                      ))
                ]),
          ],
        ));
  }
}
