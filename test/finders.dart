import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

class WidgetChildTypeFinder extends ChainedFinder {
  WidgetChildTypeFinder(Finder super.parent, this.childType);

  final Type childType;

  @override
  String get description => '$parent (considering only types of children)';

  @override
  Iterable<Element> filter(Iterable<Element> parentCandidates) sync* {
    for (final Element candidate in parentCandidates) {
      var elements = collectAllElementsFrom(candidate, skipOffstage: false);
      for (var e in elements) {
        if (e.widget.runtimeType == childType) {
          yield e;
        }
      }
    }
  }
}

class WidgetChildTextFinder extends ChainedFinder {
  WidgetChildTextFinder(Finder super.parent, this.childTextIncludes);

  final String? childTextIncludes;

  @override
  String get description => '$parent (considering only types of children)';

  @override
  Iterable<Element> filter(Iterable<Element> parentCandidates) sync* {
    for (final Element candidate in parentCandidates) {
      var elements = collectAllElementsFrom(candidate, skipOffstage: false);
      for (var e in elements) {
        if ((e.widget.runtimeType == Text &&
                (e.widget as Text).data!.contains(childTextIncludes!)) ||
            ((e.widget.runtimeType == SelectableText &&
                (e.widget as SelectableText).data != null &&
                (e.widget as SelectableText)
                    .data!
                    .contains(childTextIncludes!)))) {
          yield e;
        }
      }
    }
  }
}

class WidgetChildIconFinder extends ChainedFinder {
  WidgetChildIconFinder(Finder super.parent, this.iconData);

  final IconData iconData;

  @override
  String get description => '$parent (considering only types of children)';

  @override
  Iterable<Element> filter(Iterable<Element> parentCandidates) sync* {
    for (final Element candidate in parentCandidates) {
      var elements = collectAllElementsFrom(candidate, skipOffstage: false);
      for (var e in elements) {
        if (e.widget is Icon && (e.widget as Icon).icon == iconData) {
          yield e;
        }
      }
    }
  }
}

class WidgetChildSemanticsFinder extends ChainedFinder {
  WidgetChildSemanticsFinder(Finder super.parent, this.tooltip);

  final String tooltip;

  @override
  String get description => '$parent (considering only types of children)';

  @override
  Iterable<Element> filter(Iterable<Element> parentCandidates) sync* {
    for (final Element candidate in parentCandidates) {
      var elements = collectAllElementsFrom(candidate, skipOffstage: false);
      for (var e in elements) {
        if (e.widget is Semantics &&
            (e.widget as Semantics).properties.tooltip == tooltip) {
          yield e;
        }
      }
    }
  }
}

extension ExtraFinders on Finder {
  Finder byChildType(Type childType) => WidgetChildTypeFinder(this, childType);
  Finder byChildTextIncludes(String? childTextIncludes) =>
      WidgetChildTextFinder(this, childTextIncludes);
  Finder byChildIcon(IconData iconData) =>
      WidgetChildIconFinder(this, iconData);
  Finder byChildSemantics(String tooltip) =>
      WidgetChildSemanticsFinder(this, tooltip);
}
