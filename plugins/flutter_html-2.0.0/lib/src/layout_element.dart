import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_html/html_parser.dart';
import 'package:flutter_html/src/anchor.dart';
import 'package:flutter_html/src/html_elements.dart';
import 'package:flutter_html/src/styled_element.dart';
import 'package:flutter_html/style.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:html/dom.dart' as dom;

/// A [LayoutElement] is an element that breaks the normal Inline flow of
/// an html document with a more complex layout. LayoutElements handle
abstract class LayoutElement extends StyledElement {
  LayoutElement({
    super.name = "[[No Name]]",
    required super.children,
    String? elementId,
    super.node,
  }) : super(
            style: Style(),
            elementId: elementId ?? "[[No ID]]");

  Widget? toWidget(RenderContext context);
}

class TableLayoutElement extends LayoutElement {
  TableLayoutElement({
    required super.name,
    required super.children,
    required dom.Element super.node,
  }) : super(elementId: node.id);

  @override
  Widget toWidget(RenderContext context) {
    return Container(
      key: AnchorKey.of(null, this),
      margin: style.margin,
      padding: style.padding,
      decoration: BoxDecoration(
        color: style.backgroundColor,
        border: style.border,
      ),
      width: style.width,
      height: style.height,
      child: LayoutBuilder(
          builder: (_, constraints) => _layoutCells(context, constraints)),
    );
  }

  Widget _layoutCells(RenderContext context, BoxConstraints constraints) {
    final rows = <TableRowLayoutElement>[];
    List<TrackSize> columnSizes = <TrackSize>[];
    for (var child in children) {
      if (child is TableStyleElement) {
        // Map <col> tags to predetermined column track sizes
        columnSizes = child.children
            .where((c) => c.name == "col")
            .map((c) {
              final span = int.tryParse(c.attributes["span"] ?? "1") ?? 1;
              final colWidth = c.attributes["width"];
              return List.generate(span, (index) {
                if (colWidth != null && colWidth.endsWith("%")) {
                  if (!constraints.hasBoundedWidth) {
                    // In a horizontally unbounded container; always wrap content instead of applying flex
                    return const IntrinsicContentTrackSize();
                  }
                  final percentageSize = double.tryParse(
                      colWidth.substring(0, colWidth.length - 1));
                  return percentageSize != null && !percentageSize.isNaN
                      ? FlexibleTrackSize(percentageSize * 0.01)
                      : const IntrinsicContentTrackSize();
                } else if (colWidth != null) {
                  final fixedPxSize = double.tryParse(colWidth);
                  return fixedPxSize != null
                      ? FixedTrackSize(fixedPxSize)
                      : const IntrinsicContentTrackSize();
                } else {
                  return const IntrinsicContentTrackSize();
                }
              });
            })
            .expand((element) => element)
            .toList(growable: false);
      } else if (child is TableSectionLayoutElement) {
        rows.addAll(child.children.whereType());
      } else if (child is TableRowLayoutElement) {
        rows.add(child);
      }
    }

    // All table rows have a height intrinsic to their (spanned) contents
    final rowSizes =
        List.generate(rows.length, (_) => const IntrinsicContentTrackSize());

    // Calculate column bounds
    int columnMax = rows
        .map((row) => row.children
            .whereType<TableCellElement>()
            .fold(0, (int value, child) => value + child.colspan))
        .fold(0, max);

    // Place the cells in the rows/columns
    final cells = <GridPlacement>[];
    final columnRowOffset = List.generate(columnMax + 1, (_) => 0);
    int rowi = 0;
    for (var row in rows) {
      int columni = 0;
      for (var child in row.children) {
        while (columnRowOffset[columni] > 0) {
          columnRowOffset[columni] = columnRowOffset[columni] - 1;
          columni++;
        }
        if (child is TableCellElement) {
          cells.add(GridPlacement(
            columnStart: columni,
            columnSpan: child.colspan,
            rowStart: rowi,
            rowSpan: child.rowspan,
            child: Container(
              width: double.infinity,
              padding: child.style.padding ?? row.style.padding,
              decoration: BoxDecoration(
                color: child.style.backgroundColor ?? row.style.backgroundColor,
                border: child.style.border ?? row.style.border,
              ),
              child: SizedBox.expand(
                child: Container(
                  alignment: child.style.alignment ??
                      style.alignment ??
                      Alignment.centerLeft,
                  child: StyledText(
                    textSpan: context.parser.parseTree(context, child, null),
                    style: child.style,
                    renderContext: context,
                  ),
                ),
              ),
            ),
          ));
          columnRowOffset[columni] = child.rowspan - 1;
          columni += child.colspan;
        }
      }
      rowi++;
    }

    // Create column tracks (insofar there were no colgroups that already defined them)
    List<TrackSize> finalColumnSizes = columnSizes.take(columnMax).toList();
    finalColumnSizes += List.generate(
        max(0, columnMax - finalColumnSizes.length),
        (_) => const IntrinsicContentTrackSize());

    return LayoutGrid(
      gridFit: GridFit.loose,
      columnSizes: finalColumnSizes,
      rowSizes: rowSizes,
      children: cells,
    );
  }
}

class TableSectionLayoutElement extends LayoutElement {
  TableSectionLayoutElement({
    required super.name,
    required super.children,
  });

  @override
  Widget toWidget(RenderContext context) {
    // Not rendered; TableLayoutElement will instead consume its children
    return const Text("TABLE SECTION");
  }
}

class TableRowLayoutElement extends LayoutElement {
  TableRowLayoutElement({
    required super.name,
    required super.children,
    required dom.Element super.node,
  });

  @override
  Widget toWidget(RenderContext context) {
    // Not rendered; TableLayoutElement will instead consume its children
    return const Text("TABLE ROW");
  }
}

class TableCellElement extends StyledElement {
  int colspan = 1;
  int rowspan = 1;

  TableCellElement({
    required super.name,
    required super.elementId,
    required super.elementClasses,
    required super.children,
    required super.style,
    required dom.Element super.node,
  }) {
    colspan = _parseSpan(this, "colspan");
    rowspan = _parseSpan(this, "rowspan");
  }

  static int _parseSpan(StyledElement element, String attributeName) {
    final spanValue = element.attributes[attributeName];
    return spanValue == null ? 1 : int.tryParse(spanValue) ?? 1;
  }
}

TableCellElement parseTableCellElement(
  dom.Element element,
  List<StyledElement> children,
) {
  final cell = TableCellElement(
    name: element.localName!,
    elementId: element.id,
    elementClasses: element.classes.toList(),
    children: children,
    node: element,
    style: Style(),
  );
  if (element.localName == "th") {
    cell.style = Style(
      fontWeight: FontWeight.bold,
    );
  }
  return cell;
}

class TableStyleElement extends StyledElement {
  TableStyleElement({
    required super.name,
    required super.children,
    required super.style,
    required dom.Element super.node,
  });
}

TableStyleElement parseTableDefinitionElement(
  dom.Element element,
  List<StyledElement> children,
) {
  switch (element.localName) {
    case "colgroup":
    case "col":
      return TableStyleElement(
        name: element.localName!,
        children: children,
        node: element,
        style: Style(),
      );
    default:
      return TableStyleElement(
        name: "[[No Name]]",
        children: children,
        node: element,
        style: Style(),
      );
  }
}

class DetailsContentElement extends LayoutElement {
  List<dom.Element> elementList;

  DetailsContentElement({
    required super.name,
    required super.children,
    required dom.Element super.node,
    required this.elementList,
  }) : super(elementId: node.id);

  @override
  Widget toWidget(RenderContext context) {
    List<InlineSpan>? childrenList = children
        .map((tree) => context.parser.parseTree(context, tree, null))
        .toList();
    List<InlineSpan> toRemove = [];
    for (InlineSpan child in childrenList) {
      if (child is TextSpan &&
          child.text != null &&
          child.text!.trim().isEmpty) {
        toRemove.add(child);
      }
    }
    for (InlineSpan child in toRemove) {
      childrenList.remove(child);
    }
    InlineSpan? firstChild =
        childrenList.isNotEmpty == true ? childrenList.first : null;
    return ExpansionTile(
        key: AnchorKey.of(null, this),
        expandedAlignment: Alignment.centerLeft,
        title: elementList.isNotEmpty == true &&
                elementList.first.localName == "summary"
            ? StyledText(
                textSpan: TextSpan(
                  style: style.generateTextStyle(),
                  children: firstChild == null ? [] : [firstChild],
                ),
                style: style,
                renderContext: context,
              )
            : const Text("Details"),
        children: [
          StyledText(
            textSpan: TextSpan(
                style: style.generateTextStyle(),
                children: getChildren(
                    childrenList,
                    context,
                    elementList.isNotEmpty == true &&
                            elementList.first.localName == "summary"
                        ? firstChild
                        : null)),
            style: style,
            renderContext: context,
          ),
        ]);
  }

  List<InlineSpan> getChildren(List<InlineSpan> children, RenderContext context,
      InlineSpan? firstChild) {
    if (firstChild != null) children.removeAt(0);
    return children;
  }
}

class EmptyLayoutElement extends LayoutElement {
  EmptyLayoutElement({required super.name}) : super(children: []);

  @override
  Widget? toWidget(context) => null;
}

LayoutElement parseLayoutElement(
  dom.Element element,
  List<StyledElement> children,
) {
  switch (element.localName) {
    case "details":
      if (children.isEmpty) {
        return EmptyLayoutElement(name: "empty");
      }
      return DetailsContentElement(
          node: element,
          name: element.localName!,
          children: children,
          elementList: element.children);
    case "table":
      return TableLayoutElement(
        name: element.localName!,
        children: children,
        node: element,
      );
    case "thead":
    case "tbody":
    case "tfoot":
      return TableSectionLayoutElement(
        name: element.localName!,
        children: children,
      );
    case "tr":
      return TableRowLayoutElement(
        name: element.localName!,
        children: children,
        node: element,
      );
    default:
      return TableLayoutElement(
          children: children, name: "[[No Name]]", node: element);
  }
}
