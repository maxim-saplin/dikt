library flutter_html;

//export style api
export 'package:flutter_html/style.dart';
//export render context api
export 'package:flutter_html/html_parser.dart';
//export src for advanced custom render uses (e.g. casting context.tree)
export 'package:flutter_html/src/layout_element.dart';
export 'package:flutter_html/src/replaced_element.dart';
export 'package:flutter_html/src/styled_element.dart';
export 'package:flutter_html/src/interactable_element.dart';

import 'package:after_layout/after_layout.dart';
import 'package:dikt/ui/elements/word_articles.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/html_parser.dart';
import 'package:flutter_html/src/html_elements.dart';
import 'package:flutter_html/style.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/dom.dart' as dom;
import 'package:ikvpack/ikvpack.dart';

Stopwatch? _globalSw;

class Html extends StatelessWidget {
  Html(
      {Key? key,
      required this.data,
      this.onLinkTap,
      this.shrinkWrap = false,
      this.tagsList = const {},
      this.style = const {},
      this.useIsolate = false,
      this.isolatePool,
      this.onBuilt,
      this.onLaidOut,
      this.sw})
      : assert(data != null),
        anchorKey = GlobalKey(),
        super(key: key);

  /// A unique key for this Html widget to ensure uniqueness of anchors
  final Key anchorKey;

  /// The HTML data passed to the widget as a String
  final String? data;

  /// A function that defines what to do when a link is tapped
  final OnTap? onLinkTap;

  /// A parameter that should be set when the HTML widget is expected to be
  /// flexible
  final bool shrinkWrap;

  /// A list of HTML tags that defines what elements are not rendered
  final Set<String> tagsList;

  /// An API that allows you to override the default style for any HTML element
  final Map<String, Style> style;

  /// Let the widget report completion of laying out via print()
  final Stopwatch? sw;

  /// Whether to paralellize some of hard work
  final bool useIsolate;

  /// Called when futured part is built
  final Function? onBuilt;

  /// Called when futured
  final Function? onLaidOut;

  /// useIsolate == true, isolatePool == null - run in compute()
  /// useIsolate == true, isolatePool != null - run as PooledJob in the provided pool
  final IsolatePool? isolatePool;

  static Set<String> get tags => new Set<String>.from(STYLED_ELEMENTS)
    ..addAll(INTERACTABLE_ELEMENTS)
    ..addAll(REPLACED_ELEMENTS)
    ..addAll(LAYOUT_ELEMENTS);
  //..addAll(TABLE_CELL_ELEMENTS)
  //..addAll(TABLE_DEFINITION_ELEMENTS);

  @override
  Widget build(BuildContext context) {
    _globalSw = sw;

    final double? width = shrinkWrap ? null : MediaQuery.of(context).size.width;

    var text = _parseHtmlToTextSpans(useIsolate);

    return _FuturedHtml(
      width: width,
      text: text,
      onLinkTap: onLinkTap,
      onBuilt: onBuilt,
      onLaidOut: onLaidOut,
    );
  }

  Future<StyledText> _parseHtmlToTextSpans(bool useIsolate) {
    var parser = HtmlParser(
      shrinkWrap: shrinkWrap,
      style: style,
      tagsList: tagsList.isEmpty ? Html.tags : tagsList,
    );

    var params = _ComputeParams(parser, data!);

    var w = useIsolate
        ? isolatePool == null
            ? compute(_computeBody, params)
            : isolatePool!.scheduleJob<StyledText>(_ParseHtmlJob(params))
        : Future<StyledText>(() {
            return _computeBody(params);
          });

    return w;
  }
}

class _ComputeParams {
  _ComputeParams(this.parser, this.data);
  final HtmlParser parser;
  final String data;
}

StyledText _computeBody(_ComputeParams params) {
  final dom.Document doc = HtmlParser.parseHTML(params.data);

  var text = params.parser.parse(doc);
  return text;
}

class _ParseHtmlJob extends PooledJob<StyledText> {
  _ParseHtmlJob(this.params);
  _ComputeParams params;

  @override
  Future<StyledText> job() async {
    return _computeBody(params);
  }
}

class _FuturedHtml extends StatelessWidget {
  const _FuturedHtml(
      {Key? key,
      required this.width,
      required this.text,
      this.onLinkTap,
      this.onBuilt,
      this.onLaidOut})
      : super(key: key);

  final double? width;
  final Future<StyledText> text;
  final OnTap? onLinkTap;
  final Function? onBuilt;
  final Function? onLaidOut;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: width,
        child: FutureBuilder<StyledText>(
          future: text,
          builder: (c, s) {
            if (s.hasData && s.data != null) {
              if (onLinkTap != null) s.data!.fixTap(onLinkTap!);

              return _FuturedBody(s.data!, onBuilt, onLaidOut);
            } else {
              return SizedBox();
            }
          },
        ));
  }
}

class _FuturedBody extends StatefulWidget {
  _FuturedBody(this.richText, this.onBuilt, this.onLaidOut);

  final StyledText richText;
  final Function? onBuilt;
  final Function? onLaidOut;

  @override
  State<_FuturedBody> createState() => _FuturedBodyState();
}

class _FuturedBodyState extends State<_FuturedBody>
    with AfterLayoutMixin<_FuturedBody> {
  @override
  void afterFirstLayout(BuildContext context) {
    if (_globalSw != null) {
      print(
          'Html._FuturedBody laidout, total ${globalSw.elapsedMilliseconds}ms');
    }
    widget.onLaidOut?.call();
  }

  @override
  Widget build(BuildContext context) {
    widget.onBuilt?.call();

    return widget.richText;
  }
}
