import 'package:flutter/material.dart';

import '../elements/loading_progress.dart';
import '../elements/lookup.dart';
import '../elements/menu_buttons.dart';
import '../responsive.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveSplitView(
        ifOnePane: (c, add) => add(const Stack(children: [
              Lookup(searchBarTopRounded: true),
              DictionaryIndexingOrLoading(),
              EmptyHints(showDictionaryStats: true, showSearchBarHint: true),
              TopButtons()
            ])),
        ifTwoPanes: (c, add) => add(
            const Stack(children: [
              Lookup(searchBarTopRounded: false),
              EmptyHints(showDictionaryStats: false, showSearchBarHint: true)
            ]),
            const Stack(children: [
              DictionaryIndexingOrLoading(),
              EmptyHints(showDictionaryStats: true, showSearchBarHint: false),
              TopButtons()
            ])));
  }
}
