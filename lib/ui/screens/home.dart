import 'package:flutter/material.dart';

import '../elements/loading_progress.dart';
import '../elements/lookup.dart';
import '../elements/menu_buttons.dart';
import '../responsive.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveSplitView(
        whenOnePaneBuilder: (c, add) => add(const Stack(children: [
              Lookup(searchBarTopRounded: true),
              DictionaryIndexingOrLoading(),
              EmptyHints(showDictionaryStats: true, showSearchBarHint: true),
              TopButtons()
            ])),
        whenTwoPanesBuilder: (c, add) => add(
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
