import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';

import '../common/preferences_singleton.dart';

int wideNarrowBreak = 500;

/// Depending on width either display two pane resizable split view or one pane
class ResponsiveSplitView extends StatefulWidget {
  const ResponsiveSplitView(
      {super.key, required this.ifOnePane, required this.ifTwoPanes});

  final void Function(BuildContext context, void Function(Widget widget) add)
      ifOnePane;
  final void Function(BuildContext context,
      void Function(Widget leftPane, Widget rightPane) add) ifTwoPanes;

  @override
  State<ResponsiveSplitView> createState() => _ResponsiveSplitViewState();
}

/// Instead of LayoutBuilder/MediaQuery.of causing frequent and expensive builds (Artical -> Html widgets) using stateful widget which respnds to events when width changes and orintation (isWide flag) need yo be updated
class _ResponsiveSplitViewState extends State<ResponsiveSplitView>
    with WidgetsBindingObserver {
  bool _isWide = true;
  late MultiSplitViewController controller;

  @override
  void didChangeMetrics() {
    var isWideNow = _checkIsWide(context);
    if (isWideNow != _isWide) {
      setState(() {
        _isWide = isWideNow;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addObserver(this);
    _isWide = _checkIsWide(context);

    controller = MultiSplitViewController(areas: [
      Area(weight: PreferencesSingleton.twoPaneRatio, minimalSize: 200),
      Area(minimalSize: 200)
    ]);
    // For some reasons that doesn't work, Feb 2023, revering to widget callback
    // controller.addListener(() {
    //   PreferencesSingleton.twoPaneRatio = controller.areas[0].weight!;
    // });
  }

  bool _checkIsWide(BuildContext context) =>
      View.of(context).physicalSize.width / View.of(context).devicePixelRatio >=
      wideNarrowBreak;
  // WidgetsBinding.instance.window.physicalSize.width /
  //     WidgetsBinding.instance.window.devicePixelRatio >=
  // wideNarrowBreak;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget w = const SizedBox();

    if (_isWide) {
      Widget lp = const SizedBox();
      Widget rp = const SizedBox();

      void addTwo(Widget leftPane, Widget rightPane) {
        lp = leftPane;
        rp = rightPane;
      }

      widget.ifTwoPanes(context, addTwo);

      w = MultiSplitViewTheme(
          data: MultiSplitViewThemeData(
              dividerThickness: 5,
              dividerPainter: DividerPainters.background(
                  highlightedColor: Theme.of(context).colorScheme.secondary)),
          child: MultiSplitView(
            controller: controller,
            onWeightChange: () {
              PreferencesSingleton.twoPaneRatio = controller.areas[0].weight!;
            },
            // not wrapping rigt pane to have it take full height on Desktop
            children: [
              _wrapInSafeArea(lp),
              defaultTargetPlatform == TargetPlatform.android ||
                      defaultTargetPlatform == TargetPlatform.iOS
                  ? _wrapInSafeArea(rp)
                  : rp
            ],
          ));
    } else {
      void addOne(Widget widget) {
        w = widget;
      }

      widget.ifOnePane(context, addOne);

      w = _wrapInSafeArea(w);
    }

    return w;
  }
}

Widget _wrapInSafeArea(Widget w) => SafeArea(
    minimum: defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows
        ? const EdgeInsets.only(top: 30)
        : EdgeInsets.zero,
    child: w);
