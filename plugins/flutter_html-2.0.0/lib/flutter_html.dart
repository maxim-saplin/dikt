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

Stopwatch? _globalSw;

class Html extends StatelessWidget {
  /// The `Html` widget takes HTML as input and displays a RichText
  /// tree of the parsed HTML content.
  ///
  /// **Attributes**
  /// **data** *required* takes in a String of HTML data (required only for `Html` constructor).
  /// **document** *required* takes in a Document of HTML data (required only for `Html.fromDom` constructor).
  ///
  /// **onLinkTap** This function is called whenever a link (`<a href>`)
  /// is tapped.
  /// **customRender** This function allows you to return your own widgets
  /// for existing or custom HTML tags.
  /// See [its wiki page](https://github.com/Sub6Resources/flutter_html/wiki/All-About-customRender) for more info.
  ///
  /// **onImageError** This is called whenever an image fails to load or
  /// display on the page.
  ///
  /// **shrinkWrap** This makes the Html widget take up only the width it
  /// needs and no more.
  ///
  /// **onImageTap** This is called whenever an image is tapped.
  ///
  /// **tagsList** Tag names in this array will be the only tags rendered. By default all tags are rendered.
  ///
  /// **style** Pass in the style information for the Html here.
  /// See [its wiki page](https://github.com/Sub6Resources/flutter_html/wiki/Style) for more info.
  Html(
      {Key? key,
      required this.data,
      this.onLinkTap,
      this.shrinkWrap = false,
      this.tagsList = const [],
      this.style = const {},
      this.useIsolate = false,
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
  final List<String> tagsList;

  /// An API that allows you to override the default style for any HTML element
  final Map<String, Style> style;

  /// Let the widget report completion of laying out via print()
  final Stopwatch? sw;

  /// Whether to paralellize some of hard work
  final bool useIsolate;

  static List<String> get tags => new List<String>.from(STYLED_ELEMENTS)
    ..addAll(INTERACTABLE_ELEMENTS)
    ..addAll(REPLACED_ELEMENTS)
    ..addAll(LAYOUT_ELEMENTS)
    ..addAll(TABLE_CELL_ELEMENTS)
    ..addAll(TABLE_DEFINITION_ELEMENTS);

  @override
  Widget build(BuildContext context) {
    _globalSw = sw;

    final double? width = shrinkWrap ? null : MediaQuery.of(context).size.width;

    var text = _parseHtmlToTextSpans(useIsolate);

    return _FuturedHtml(
      width: width,
      text: text,
      onLinkTap: onLinkTap,
    );
  }

  static StyledText _computeBody(_ComputeParams params) {
    final dom.Document doc = HtmlParser.parseHTML(params.data);

    var text = params.parser.parse(doc);
    return text;
  }

  Future<StyledText> _parseHtmlToTextSpans(bool useIsolate) {
    var parser = HtmlParser(
      shrinkWrap: shrinkWrap,
      style: style,
      tagsList: tagsList.isEmpty ? Html.tags : tagsList,
    );

    var w = useIsolate
        ? compute(_computeBody, _ComputeParams(parser, data!))
        : Future<StyledText>(() {
            return _computeBody(_ComputeParams(parser, data!));
          });

    return w;
  }
}

class _ComputeParams {
  _ComputeParams(this.parser, this.data);
  final HtmlParser parser;
  final String data;
}

class _FuturedHtml extends StatelessWidget {
  const _FuturedHtml(
      {Key? key, required this.width, required this.text, this.onLinkTap})
      : super(key: key);

  final double? width;
  final Future<StyledText> text;
  final OnTap? onLinkTap;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: width,
        child: FutureBuilder<StyledText>(
          future: text,
          builder: (c, s) {
            if (s.hasData && s.data != null) {
              if (onLinkTap != null) s.data!.fixTap(onLinkTap!);
              return _FuturedBody(s.data!);
            } else {
              return SizedBox();
            }
          },
        ));
  }
}

class _FuturedBody extends StatefulWidget {
  _FuturedBody(this.richText);

  final StyledText richText;

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
  }

  @override
  Widget build(BuildContext context) {
    return widget.richText;
  }
}
