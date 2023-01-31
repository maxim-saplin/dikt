import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';

int wideNarrowBreak = 500;

/// Depending on width either display two pane resizable split view or one pane
class AdaptiveSplitView extends StatelessWidget {
  const AdaptiveSplitView(
      {super.key, required this.ifOnePane, required this.ifTwoPanes});

  final void Function(BuildContext context, void Function(Widget widget) add)
      ifOnePane;
  final void Function(BuildContext context,
      void Function(Widget leftPane, Widget rightPane) add) ifTwoPanes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= wideNarrowBreak) {
        Widget lp = const SizedBox();
        Widget rp = const SizedBox();

        void addTwo(Widget leftPane, Widget rightPane) {
          lp = leftPane;
          rp = rightPane;
        }

        ifTwoPanes(context, addTwo);

        return MultiSplitViewTheme(
            data: MultiSplitViewThemeData(
                dividerThickness: 5,
                dividerPainter: DividerPainters.background(
                    highlightedColor: Theme.of(context).colorScheme.secondary)),
            child: MultiSplitView(
              initialAreas: [
                Area(weight: 0.35, minimalSize: 200),
                Area(minimalSize: 200)
              ],
              children: [lp, rp],
            ));
      } else {
        Widget w = const SizedBox();

        void addOne(Widget widget) {
          w = widget;
        }

        ifOnePane(context, addOne);

        return w;
      }
    });
  }
}
