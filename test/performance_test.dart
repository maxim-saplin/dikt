import 'package:test/test.dart';

void main() {
  //plugins/flutter_html-2.0.0/lib/html_parser.dart
  test('Sets are faster than lists when doing contains()', () {
    var strings = ['a', 'div', 'span', 'fdf', 'i', 'head', 'table'];

    const iterations_l1 = 5;
    const iterations_l2 = 1000000;
    bool contains = false;

    for (var j = 0; j < iterations_l2; j++) {
      for (var k = 0; k < strings.length; k++) {
        contains = STYLED_ELEMENTS.contains(strings[k]) ||
            INTERACTABLE_ELEMENTS.contains(strings[k]) ||
            REPLACED_ELEMENTS.contains(strings[k]) ||
            LAYOUT_ELEMENTS.contains(strings[k]) ||
            TABLE_CELL_ELEMENTS.contains(strings[k]) ||
            TABLE_DEFINITION_ELEMENTS.contains(strings[k]);
      }
    }

    for (var j = 0; j < iterations_l2; j++) {
      for (var k = 0; k < strings.length; k++) {
        contains = STYLED_ELEMENTS_L.contains(strings[k]) ||
            INTERACTABLE_ELEMENTS_L.contains(strings[k]) ||
            REPLACED_ELEMENTS_L.contains(strings[k]) ||
            LAYOUT_ELEMENTS_L.contains(strings[k]) ||
            TABLE_CELL_ELEMENTS_L.contains(strings[k]) ||
            TABLE_DEFINITION_ELEMENTS_L.contains(strings[k]);
      }
    }

    var swSet = Stopwatch();
    swSet.start();

    for (var i = 0; i < iterations_l1; i++) {
      for (var j = 0; j < iterations_l2; j++) {
        for (var k = 0; k < strings.length; k++) {
          contains = STYLED_ELEMENTS.contains(strings[k]) ||
              INTERACTABLE_ELEMENTS.contains(strings[k]) ||
              REPLACED_ELEMENTS.contains(strings[k]) ||
              LAYOUT_ELEMENTS.contains(strings[k]) ||
              TABLE_CELL_ELEMENTS.contains(strings[k]) ||
              TABLE_DEFINITION_ELEMENTS.contains(strings[k]);
        }
      }
    }

    swSet.stop();

    var swList = Stopwatch();
    swList.start();

    for (var i = 0; i < iterations_l1; i++) {
      for (var j = 0; j < iterations_l2; j++) {
        for (var k = 0; k < strings.length; k++) {
          contains = STYLED_ELEMENTS_L.contains(strings[k]) ||
              INTERACTABLE_ELEMENTS_L.contains(strings[k]) ||
              REPLACED_ELEMENTS_L.contains(strings[k]) ||
              LAYOUT_ELEMENTS_L.contains(strings[k]) ||
              TABLE_CELL_ELEMENTS_L.contains(strings[k]) ||
              TABLE_DEFINITION_ELEMENTS_L.contains(strings[k]);
        }
      }
    }

    swList.stop();
    print('Map avg: ${swSet.elapsedMilliseconds / iterations_l1}ms');
    print('List avg: ${swList.elapsedMilliseconds / iterations_l1}ms');
    expect(swSet.elapsedMilliseconds < swList.elapsedMilliseconds, true);
    expect(contains, contains);
  });

  // This one actually fails as searching on short lists is faster than on sets
  test('Sets are faster than lists when doing contains() on small collection',
      () {
    var strings = ['a', 'div', 'span', 'fdf', 'i', 'head', 'table'];

    const iterations_l1 = 5;
    const iterations_l2 = 1000000;
    bool contains = false;

    for (var j = 0; j < iterations_l2; j++) {
      for (var k = 0; k < strings.length; k++) {
        contains = INTERACTABLE_ELEMENTS.contains(strings[k]) ||
            TABLE_CELL_ELEMENTS.contains(strings[k]) ||
            TABLE_DEFINITION_ELEMENTS.contains(strings[k]);
      }
    }

    for (var j = 0; j < iterations_l2; j++) {
      for (var k = 0; k < strings.length; k++) {
        contains = INTERACTABLE_ELEMENTS_L.contains(strings[k]) ||
            TABLE_CELL_ELEMENTS_L.contains(strings[k]) ||
            TABLE_DEFINITION_ELEMENTS_L.contains(strings[k]);
      }
    }

    var swSet = Stopwatch();
    swSet.start();

    for (var i = 0; i < iterations_l1; i++) {
      for (var j = 0; j < iterations_l2; j++) {
        for (var k = 0; k < strings.length; k++) {
          contains = INTERACTABLE_ELEMENTS.contains(strings[k]) ||
              TABLE_CELL_ELEMENTS.contains(strings[k]) ||
              TABLE_DEFINITION_ELEMENTS.contains(strings[k]);
        }
      }
    }

    swSet.stop();

    var swList = Stopwatch();
    swList.start();

    for (var i = 0; i < iterations_l1; i++) {
      for (var j = 0; j < iterations_l2; j++) {
        for (var k = 0; k < strings.length; k++) {
          contains = INTERACTABLE_ELEMENTS_L.contains(strings[k]) ||
              TABLE_CELL_ELEMENTS_L.contains(strings[k]) ||
              TABLE_DEFINITION_ELEMENTS_L.contains(strings[k]);
        }
      }
    }

    swList.stop();
    print('Map avg: ${swSet.elapsedMilliseconds / iterations_l1}ms');
    print('List avg: ${swList.elapsedMilliseconds / iterations_l1}ms');
    expect(swSet.elapsedMilliseconds < swList.elapsedMilliseconds, true);
    expect(contains, contains);
  }, skip: true);
}

const STYLED_ELEMENTS = {
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

const INTERACTABLE_ELEMENTS = {
  "a",
};

const REPLACED_ELEMENTS = {
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

const LAYOUT_ELEMENTS = {
  "details",
  "table",
  "tr",
  "tbody",
  "tfoot",
  "thead",
};

const TABLE_CELL_ELEMENTS = {"th", "td"};

const TABLE_DEFINITION_ELEMENTS = {"col", "colgroup"};

const STYLED_ELEMENTS_L = [
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

const INTERACTABLE_ELEMENTS_L = [
  "a",
];

const REPLACED_ELEMENTS_L = [
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

const LAYOUT_ELEMENTS_L = [
  "details",
  "table",
  "tr",
  "tbody",
  "tfoot",
  "thead",
];

const TABLE_CELL_ELEMENTS_L = ["th", "td"];

const TABLE_DEFINITION_ELEMENTS_L = ["col", "colgroup"];
