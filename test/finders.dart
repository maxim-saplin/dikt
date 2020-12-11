import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class WidgetChildTypeFinder extends ChainedFinder {
  WidgetChildTypeFinder(Finder parent, this.childType) : super(parent);

  final Type childType;

  @override
  String get description =>
      '${parent.description} (considering only types of children)';

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
  WidgetChildTextFinder(Finder parent, this.childTextIncludes) : super(parent);

  final String childTextIncludes;

  @override
  String get description =>
      '${parent.description} (considering only types of children)';

  @override
  Iterable<Element> filter(Iterable<Element> parentCandidates) sync* {
    for (final Element candidate in parentCandidates) {
      var elements = collectAllElementsFrom(candidate, skipOffstage: false);
      for (var e in elements) {
        if (e.widget.runtimeType == Text &&
            (e.widget as Text).data.contains(childTextIncludes)) {
          yield e;
        }
      }
    }
  }
}

class WidgetChildIconFinder extends ChainedFinder {
  WidgetChildIconFinder(Finder parent, this.iconData) : super(parent);

  final IconData iconData;

  @override
  String get description =>
      '${parent.description} (considering only types of children)';

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

extension ExtraFinders on Finder {
  Finder byChildType(Type childType) => WidgetChildTypeFinder(this, childType);
  Finder byChildText(String childTextIncludes) =>
      WidgetChildTextFinder(this, childTextIncludes);
  Finder byChildIcon(IconData iconData) =>
      WidgetChildIconFinder(this, iconData);
}
