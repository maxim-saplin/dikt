import 'package:dikt/ui/elements/menu_buttons.dart';
import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';

import '../panes/lookup.dart';

int wideNarrowThreshold = 500;

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      Widget x = constraints.maxWidth >= wideNarrowThreshold
          ? MultiSplitViewTheme(
              data: MultiSplitViewThemeData(
                  dividerThickness: 5,
                  dividerPainter: DividerPainters.background(
                      highlightedColor:
                          Theme.of(context).colorScheme.secondary)),
              child: MultiSplitView(
                initialAreas: [(Area(weight: 0.35))],
                children: const [
                  Lookup(searchBarTopRounded: false),
                  Center(child: Text('Article here'))
                ],
              ))
          : const Lookup(searchBarTopRounded: true);

      x = Stack(
        children: [x, const TopButtons()],
      );

      return x;
    });
  }
}
