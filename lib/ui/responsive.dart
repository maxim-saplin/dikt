import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';

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

  @override
  void didChangeMetrics() {
    var isWideNow = _checkIsWide();
    if (isWideNow != _isWide) {
      setState(() {
        _isWide = isWideNow;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isWide = _checkIsWide();
  }

  bool _checkIsWide() =>
      WidgetsBinding.instance.window.physicalSize.width /
          WidgetsBinding.instance.window.devicePixelRatio >=
      wideNarrowBreak;

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
            initialAreas: [
              Area(weight: 0.35, minimalSize: 200),
              Area(minimalSize: 200)
            ],
            children: [_wrapInSafeArea(lp), _wrapInSafeArea(rp)],
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
