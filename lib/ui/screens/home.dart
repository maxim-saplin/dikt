import 'package:dikt/ui/adaptive.dart';
import 'package:dikt/ui/elements/menu_buttons.dart';
import 'package:flutter/material.dart';

import '../panes/lookup.dart';

int wideNarrowThreshold = 500;

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      AdaptiveSplitView(
          ifOnePane: (c, add) => add(const Lookup(searchBarTopRounded: true)),
          ifTwoPanes: (c, add) => add(const Lookup(searchBarTopRounded: false),
              const Center(child: Text('Article here')))),
      const TopButtons()
    ]);
  }
}
