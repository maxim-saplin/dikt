import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_html/html_parser.dart';
import 'package:flutter_html/src/anchor.dart';
import 'package:flutter_html/src/html_elements.dart';
import 'package:flutter_html/style.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:html/dom.dart' as dom;

/// A [ReplacedElement] is a type of [StyledElement] that does not require its [children] to be rendered.
///
/// A [ReplacedElement] may use its children nodes to determine relevant information
/// (e.g. <video>'s <source> tags), but the children nodes will not be saved as [children].
abstract class ReplacedElement extends StyledElement {
  PlaceholderAlignment alignment;

  ReplacedElement({
    required super.name,
    required super.style,
    required super.elementId,
    super.node,
    this.alignment = PlaceholderAlignment.aboveBaseline,
  }) : super(
            children: []);

  static List<String?> parseMediaSources(List<dom.Element> elements) {
    return elements
        .where((element) => element.localName == 'source')
        .map((element) {
      return element.attributes['src'];
    }).toList();
  }

  Widget? toWidget(RenderContext context);
}

/// [TextContentElement] is a [ContentElement] with plaintext as its content.
class TextContentElement extends ReplacedElement {
  String? text;
  dom.Node? node;

  TextContentElement({
    required super.style,
    required this.text,
    this.node,
    dom.Element? element,
  }) : super(
            name: "[text]",
            node: element,
            elementId: "[[No ID]]");

  @override
  String toString() {
    return "\"${text!.replaceAll("\n", "\\n")}\"";
  }

  @override
  Widget? toWidget(context) => null;
}

/// [SvgContentElement] is a [ReplacedElement] with an SVG as its contents.
class SvgContentElement extends ReplacedElement {
  final String data;
  final double? width;
  final double? height;

  SvgContentElement({
    required super.name,
    required this.data,
    required this.width,
    required this.height,
    required dom.Element super.node,
  }) : super(style: Style(), elementId: node.id);

  @override
  Widget toWidget(RenderContext context) {
    return SvgPicture.string(
      data,
      key: AnchorKey.of(null, this),
      width: width,
      height: height,
    );
  }
}

class EmptyContentElement extends ReplacedElement {
  EmptyContentElement({super.name = "empty"})
      : super(style: Style(), elementId: "[[No ID]]");

  @override
  Widget? toWidget(context) => null;
}

class RubyElement extends ReplacedElement {
  @override
  dom.Element element;

  RubyElement({required this.element, super.name = "ruby"})
      : super(
            alignment: PlaceholderAlignment.middle,
            style: Style(),
            elementId: element.id);

  @override
  Widget toWidget(RenderContext context) {
    dom.Node? textNode;
    List<Widget> widgets = <Widget>[];
    //TODO calculate based off of parent font size.
    final rubySize = max(9.0, context.style.fontSize!.size! / 2);
    final rubyYPos = rubySize + rubySize / 2;
    for (var c in element.nodes) {
      if (c.nodeType == dom.Node.TEXT_NODE) {
        textNode = c;
      }
      if (c is dom.Element) {
        if (c.localName == "rt" && textNode != null) {
          final widget = Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                  alignment: Alignment.bottomCenter,
                  child: Center(
                      child: Transform(
                          transform:
                              Matrix4.translationValues(0, -(rubyYPos), 0),
                          child: Text(c.innerHtml,
                              style: context.style
                                  .generateTextStyle()
                                  .copyWith(fontSize: rubySize))))),
              Text(textNode.text!.trim(),
                  style: context.style.generateTextStyle()),
            ],
          );
          widgets.add(widget);
        }
      }
    }
    return Row(
      key: AnchorKey.of(null, this),
      crossAxisAlignment: CrossAxisAlignment.end,
      textBaseline: TextBaseline.alphabetic,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }
}

ReplacedElement parseReplacedElement(dom.Element element) {
  switch (element.localName) {
    case "br":
      return TextContentElement(
          text: "\n",
          style: Style(whiteSpace: WhiteSpace.pre),
          element: element,
          node: element);
    case "svg":
      return SvgContentElement(
        name: "svg",
        data: element.outerHtml,
        width: double.tryParse(element.attributes['width'] ?? ""),
        height: double.tryParse(element.attributes['height'] ?? ""),
        node: element,
      );
    case "ruby":
      return RubyElement(
        element: element,
      );
    default:
      return EmptyContentElement(
          name: element.localName == null ? "[[No Name]]" : element.localName!);
  }
}
