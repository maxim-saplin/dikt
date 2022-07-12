// ignore_for_file: avoid_print

import 'package:test/test.dart';

void main() {
  //plugins/flutter_html-2.0.0/lib/html_parser.dart
  test('Sets are faster than lists when doing contains()', () {
    var strings = ['a', 'div', 'span', 'fdf', 'i', 'head', 'table'];

    const iterationsL1 = 5;
    const iterationsL2 = 1000000;
    bool contains = false;

    for (var j = 0; j < iterationsL2; j++) {
      for (var k = 0; k < strings.length; k++) {
        contains = styledElements.contains(strings[k]) ||
            interactableElements.contains(strings[k]) ||
            replacedElements.contains(strings[k]) ||
            layoutElements.contains(strings[k]) ||
            tableCellElements.contains(strings[k]) ||
            tableDefinitionElements.contains(strings[k]);
      }
    }

    for (var j = 0; j < iterationsL2; j++) {
      for (var k = 0; k < strings.length; k++) {
        contains = styledElementsL.contains(strings[k]) ||
            interactableElementsL.contains(strings[k]) ||
            replacedElementsL.contains(strings[k]) ||
            layoutElementsL.contains(strings[k]) ||
            tableCellElementsL.contains(strings[k]) ||
            tableDefinitionElementsL.contains(strings[k]);
      }
    }

    var swSet = Stopwatch();
    swSet.start();

    for (var i = 0; i < iterationsL1; i++) {
      for (var j = 0; j < iterationsL2; j++) {
        for (var k = 0; k < strings.length; k++) {
          contains = styledElements.contains(strings[k]) ||
              interactableElements.contains(strings[k]) ||
              replacedElements.contains(strings[k]) ||
              layoutElements.contains(strings[k]) ||
              tableCellElements.contains(strings[k]) ||
              tableDefinitionElements.contains(strings[k]);
        }
      }
    }

    swSet.stop();

    var swList = Stopwatch();
    swList.start();

    for (var i = 0; i < iterationsL1; i++) {
      for (var j = 0; j < iterationsL2; j++) {
        for (var k = 0; k < strings.length; k++) {
          contains = styledElementsL.contains(strings[k]) ||
              interactableElementsL.contains(strings[k]) ||
              replacedElementsL.contains(strings[k]) ||
              layoutElementsL.contains(strings[k]) ||
              tableCellElementsL.contains(strings[k]) ||
              tableDefinitionElementsL.contains(strings[k]);
        }
      }
    }

    swList.stop();
    print('Map avg: ${swSet.elapsedMilliseconds / iterationsL1}ms');
    print('List avg: ${swList.elapsedMilliseconds / iterationsL1}ms');
    expect(swSet.elapsedMilliseconds < swList.elapsedMilliseconds, true);
    expect(contains, contains);
  }, skip: true);

  // This one actually fails as searching on short lists is faster than on sets
  test('Sets are faster than lists when doing contains() on small collection',
      () {
    var strings = ['a', 'div', 'span', 'fdf', 'i', 'head', 'table'];

    const iterationsL1 = 5;
    const iterationsL2 = 1000000;
    bool contains = false;

    for (var j = 0; j < iterationsL2; j++) {
      for (var k = 0; k < strings.length; k++) {
        contains = interactableElements.contains(strings[k]) ||
            tableCellElements.contains(strings[k]) ||
            tableDefinitionElements.contains(strings[k]);
      }
    }

    for (var j = 0; j < iterationsL2; j++) {
      for (var k = 0; k < strings.length; k++) {
        contains = interactableElementsL.contains(strings[k]) ||
            tableCellElementsL.contains(strings[k]) ||
            tableDefinitionElementsL.contains(strings[k]);
      }
    }

    var swSet = Stopwatch();
    swSet.start();

    for (var i = 0; i < iterationsL1; i++) {
      for (var j = 0; j < iterationsL2; j++) {
        for (var k = 0; k < strings.length; k++) {
          contains = interactableElements.contains(strings[k]) ||
              tableCellElements.contains(strings[k]) ||
              tableDefinitionElements.contains(strings[k]);
        }
      }
    }

    swSet.stop();

    var swList = Stopwatch();
    swList.start();

    for (var i = 0; i < iterationsL1; i++) {
      for (var j = 0; j < iterationsL2; j++) {
        for (var k = 0; k < strings.length; k++) {
          contains = interactableElementsL.contains(strings[k]) ||
              tableCellElementsL.contains(strings[k]) ||
              tableDefinitionElementsL.contains(strings[k]);
        }
      }
    }

    swList.stop();
    print('Map avg: ${swSet.elapsedMilliseconds / iterationsL1}ms');
    print('List avg: ${swList.elapsedMilliseconds / iterationsL1}ms');
    expect(swSet.elapsedMilliseconds < swList.elapsedMilliseconds, true);
    expect(contains, contains);
  }, skip: true);
}

const styledElements = {
  "abbr",
  "acronym",
  "address",
  "b",
  "bdi",
  "bdo",
  "big",
  "cite",
  "code",
  "data",
  "del",
  "dfn",
  "em",
  "font",
  "i",
  "ins",
  "kbd",
  "mark",
  "q",
  "s",
  "samp",
  "small",
  "span",
  "strike",
  "strong",
  "sub",
  "sup",
  "time",
  "tt",
  "u",
  "var",
  "wbr",

  //BLOCK ELEMENTS
  "article",
  "aside",
  "blockquote",
  "body",
  "center",
  "dd",
  "div",
  "dl",
  "dt",
  "figcaption",
  "figure",
  "footer",
  "h1",
  "h2",
  "h3",
  "h4",
  "h5",
  "h6",
  "header",
  "hr",
  "html",
  "li",
  "main",
  "nav",
  "noscript",
  "ol",
  "p",
  "pre",
  "section",
  "summary",
  "ul",
};

const interactableElements = {
  "a",
};

const replacedElements = {
  "audio",
  "br",
  "head",
  "iframe",
  "img",
  "svg",
  "template",
  "video",
  "rp",
  "rt",
  "ruby",
  "math",
};

const layoutElements = {
  "details",
  "table",
  "tr",
  "tbody",
  "tfoot",
  "thead",
};

const tableCellElements = {"th", "td"};

const tableDefinitionElements = {"col", "colgroup"};

const styledElementsL = [
  "abbr",
  "acronym",
  "address",
  "b",
  "bdi",
  "bdo",
  "big",
  "cite",
  "code",
  "data",
  "del",
  "dfn",
  "em",
  "font",
  "i",
  "ins",
  "kbd",
  "mark",
  "q",
  "s",
  "samp",
  "small",
  "span",
  "strike",
  "strong",
  "sub",
  "sup",
  "time",
  "tt",
  "u",
  "var",
  "wbr",

  //BLOCK ELEMENTS
  "article",
  "aside",
  "blockquote",
  "body",
  "center",
  "dd",
  "div",
  "dl",
  "dt",
  "figcaption",
  "figure",
  "footer",
  "h1",
  "h2",
  "h3",
  "h4",
  "h5",
  "h6",
  "header",
  "hr",
  "html",
  "li",
  "main",
  "nav",
  "noscript",
  "ol",
  "p",
  "pre",
  "section",
  "summary",
  "ul",
];

const interactableElementsL = [
  "a",
];

const replacedElementsL = [
  "audio",
  "br",
  "head",
  "iframe",
  "img",
  "svg",
  "template",
  "video",
  "rp",
  "rt",
  "ruby",
  "math",
];

const layoutElementsL = [
  "details",
  "table",
  "tr",
  "tbody",
  "tfoot",
  "thead",
];

const tableCellElementsL = ["th", "td"];

const tableDefinitionElementsL = ["col", "colgroup"];
