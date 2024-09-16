import 'dart:async';
import 'dart:collection';
import 'package:after_layout/after_layout.dart';
import 'package:dikt/common/helpers.dart';
import 'package:dikt/common/i18n.dart';
import 'package:dikt/common/isolate_pool.dart';
import 'package:dikt/ui/themes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dikt/models/master_dictionary.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

import '../routes.dart';

// Started when top level widget build() is called and used to measure article widgets layouts - essentialy time to dispolay
Stopwatch _globalSw = Stopwatch();

/// The widget is composed of a number of future builders + part of Html rendering (creating text spans)
/// is done o external isolates. To avoid blinking and show UI after it is ready Offstage is used
/// to wait on all FutureBuilders and present complete UI
/// Besides widget caching is used to avoid expensive rebuilds of Html widgets
/// The approach kinda sucks, there're many cases that don't work and require workarounds, e.g. not able
/// to have duplicate entries in Navogator route history, the need to invalidate cache in multiple cases (e.g. prefference change, dictionary change, 1/2 pane chage)
/// There's also some tricky bug when dealing with global key for dictionaries, under some navigation cases global keys have null context
//TODO, add automation, e.g navigating to series of articles, some twice and scrolling/jumping in each case, having lookup word entered and doing nav
class WordArticles extends StatefulWidget {
  const WordArticles(
      {super.key,
      required this.articles,
      required this.word,
      required this.twoPaneMode,

      /// Callback to call in order to navigate to a word within an article
      this.showAnotherWord});

  final Future<List<Article>>? articles;
  final String word;
  final bool twoPaneMode;
  final Function(String word)? showAnotherWord;

  @override
  State<WordArticles> createState() => _WordArticlesState();
}

class _WordArticlesState extends State<WordArticles> {
  // List of dictionaries is only known when all articles are loaded and corresponding future is completed, using this completer to trigger UI for dictionaries
  final _bottomDictionariesCompleter = Completer<
      Tuple<List<DropdownMenuItem<String>>, Map<String, GlobalKey>>>();

  final _offstageCompleter = Completer();
  final _selectorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    Widget w = const SizedBox();

    if (WordArticlesCache._cacheEnabled &&
        WordArticlesCache._cacheItemExists(widget.word)) {
      w = WordArticlesCache._getCacheItem(widget.word);
    } else {
      _globalSw.reset();
      _globalSw.start();

      if (widget.articles == null) {
        return const SizedBox();
      }

      final ScrollController scrollController =
          SinglePositionScrollController();

      Widget x = ColoredBox(
          color: Theme.of(context).cardColor,
          child: Stack(children: [
            // Article list
            _FuturedArticles(
                word: widget.word,
                articles: widget.articles!,
                offstageCompleter: _offstageCompleter,
                bottomDictionariesCompleter: _bottomDictionariesCompleter,
                scrollController: scrollController,
                showAnotherWord: widget.showAnotherWord),
            // Title with selectable text - word
            Container(
                padding: const EdgeInsets.fromLTRB(18, 15, 18, 0),
                color: Theme.of(context).cardColor,
                height: 39.0,
                width: 1000,
                child: SelectableText(
                  widget.word,
                  style: Theme.of(context).textTheme.headlineSmall,
                )),
          ]));

      x = Stack(children: [
        ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            child: widget.twoPaneMode ? Center(child: x) : x),
        // Bottom buttons
        Positioned(
          bottom: 0.0,
          left: 0.0,
          right: 0.0,
          height: widget.twoPaneMode ? ownTheme(context).searchBarHeight : 50,
          child: Stack(alignment: Alignment.bottomRight, children: [
            FutureBuilder<
                    Tuple<List<DropdownMenuItem<String>>,
                        Map<String, GlobalKey>>>(
                future: _bottomDictionariesCompleter.future,
                builder: (c, s) => s.hasData && s.data != null
                    ? _DictionarySelector(
                        key: _selectorKey,
                        dictionaries: s.data!.value1,
                        dicsToKeys: s.data!.value2,
                        scrollController: scrollController)
                    : const SizedBox()),
            Container(
                color: Theme.of(context).cardColor,
                child: Flex(
                    direction: Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // Back button
                      _BottomButton(
                        twoPaneMode: widget.twoPaneMode,
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Theme.of(context).iconTheme.color,
                          size: 18,
                        ),
                        onPressed: () {
                          // Due to cachning and custom routing this context might be bad, using ad-hoc nav
                          //Navigator.of(context).pop();
                          Routes.goBack();
                        },
                      ),
                      _BottomButton(
                        twoPaneMode: widget.twoPaneMode,
                        icon: Icon(
                          Icons.launch_rounded,
                          color: Theme.of(context).iconTheme.color,
                          size: 20,
                        ),
                        onPressed: () {
                          // Do click on a DropDownList
                          GestureDetector? detector;
                          void searchForGestureDetector(BuildContext? element) {
                            element?.visitChildElements((element) {
                              if (element.widget is GestureDetector) {
                                detector = element.widget as GestureDetector?;
                              } else {
                                searchForGestureDetector(element);
                              }
                            });
                          }

                          searchForGestureDetector(_selectorKey.currentContext);
                          assert(detector != null);

                          detector?.onTap?.call();
                        },
                      ),
                    ])),
          ]),
        ),
        // Dictionary selector
      ]);

      w = FutureBuilder(
          future: _offstageCompleter.future,
          builder: (c, s) => !s.hasData
              // Ussing Offstage to prepaer all article and present them in one frame when all are ready
              // Using stack and _Empty to avoid any jumps and keep width of the widget occupied
              ? Offstage(offstage: true, child: x)
              : Offstage(offstage: false, child: x));

      WordArticlesCache._addItemToCache(widget.word, w);
    }

    return w;
  }
}

class _BottomButton extends StatelessWidget {
  const _BottomButton(
      {required this.twoPaneMode, required this.onPressed, required this.icon});

  final bool twoPaneMode;
  final void Function() onPressed;
  final Icon icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
        flex: 1,
        child: TextButton(
          onPressed: onPressed,
          child: SizedBox(
              height: twoPaneMode ? ownTheme(context).searchBarHeight : 50,
              child: icon),
        ));
  }
}

/// Awaits for articles from Futures and passes their contents for rendering
class _FuturedArticles extends StatelessWidget {
  const _FuturedArticles(
      {required this.word,
      required this.articles,
      required this.offstageCompleter,
      required this.bottomDictionariesCompleter,
      required this.scrollController,
      required this.showAnotherWord});

  static EdgeInsets headerInsets = const EdgeInsets.fromLTRB(0, 30, 0, 50);

  final String word;
  final Future<List<Article>> articles;
  final Completer offstageCompleter;
  final Completer<Tuple<List<DropdownMenuItem<String>>, Map<String, GlobalKey>>>
      bottomDictionariesCompleter;
  final ScrollController scrollController;
  final Function(String word)? showAnotherWord;

  @override
  Widget build(BuildContext context) {
    var w = FutureBuilder<List<Article>>(
      //future: Future.delayed(const Duration(seconds: 2), () => articles),
      future: articles,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var articles = snapshot.data ?? [];

          if (articles.isEmpty) {
            articles = [
              Article(
                  word,
                  '\'$word\' ${'not found in the available dictionaries'.i18n}',
                  'N/A')
            ];
          }

          return _FuturedArticleBodies(articles, offstageCompleter,
              bottomDictionariesCompleter, scrollController, showAnotherWord);
        }
        return const SizedBox();
      },
    );

    //debugPrint('_FuturedArticle built ${sw.elapsedMilliseconds}ms');
    return w;
  }
}

/// Each individual article is built via Html renderer which potentially can use external isolate. Time to render/layout is measured and printed in debug log
class _FuturedArticleBodies extends StatefulWidget {
  const _FuturedArticleBodies(
      this.articles,
      this.offstageCompleter,
      this.bottomDictionariesCompleter,
      this.scrollController,
      this.showAnotherWord);
  final List<Article> articles;
  final Completer offstageCompleter;
  final Completer<Tuple<List<DropdownMenuItem<String>>, Map<String, GlobalKey>>>
      bottomDictionariesCompleter;
  final ScrollController scrollController;
  final Function(String word)? showAnotherWord;

  @override
  State<_FuturedArticleBodies> createState() => _FuturedArticleBodiesState();
}

class _FuturedArticleBodiesState extends State<_FuturedArticleBodies>
    with AfterLayoutMixin<_FuturedArticleBodies> {
  var sw = Stopwatch();

  @override
  void afterFirstLayout(BuildContext context) {
    debugPrint(
        '_FuturedArticleBody laidout ${sw.elapsedMilliseconds}ms, total ${_globalSw.elapsedMilliseconds}');
  }

  final UniqueKey _scrollKey = UniqueKey();

  int _builtCounter = 0;
  int _laidoutCounter = 0;
  final _dicsToKeys = <String, GlobalKey>{};

  @override
  Widget build(BuildContext context) {
    sw.reset();
    sw.start();

    var dictionaries = widget.articles
        .map((a) => DropdownMenuItem<String>(
            alignment: Alignment.centerRight,
            value: a.dictionaryName,
            child: Text(
              a.dictionaryName,
              style: Theme.of(context).textTheme.titleSmall,
            )))
        .toList();

    // Aggregate all dictionaries in bottom nav bar
    if (!widget.bottomDictionariesCompleter.isCompleted) {
      widget.bottomDictionariesCompleter
          .complete(Tuple(dictionaries, _dicsToKeys));
    }

    var w = Padding(
        key: _scrollKey,
        padding: _FuturedArticles.headerInsets,
        child: Scrollbar(
            controller: widget.scrollController,
            child: CustomScrollView(
              controller: widget.scrollController,
              physics: const BouncingScrollPhysics(),
              semanticChildCount: widget.articles.length,
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              slivers: widget.articles.map((article) {
                if (!_dicsToKeys.keys.contains(article.dictionaryName)) {
                  _dicsToKeys[article.dictionaryName] = GlobalKey();
                }
                var key = _dicsToKeys[article.dictionaryName];

                return SliverStickyHeader(
                  key: key,
                  header: _getHtmlHeader(
                      context, dictionaries, _dicsToKeys, article),
                  // Html widget has future builder inside and display empty UI when rendering is not ready but also provides onLaidOut callback to let know that future is received and view is rendered
                  sliver: _getSliverWithHtml(context, article, _dicsToKeys),
                );
              }).toList(),
            )));

    // debugPrint(
    //     '_FuturedArticleBody built ${sw.elapsedMilliseconds}ms, total ${globalSw.elapsedMilliseconds}');

    // return FutureBuilder(
    //     future: _offstageCompleter.future,
    //     builder: (c, s) => !s.hasData
    //         ? AnimatedOpacity(
    //             duration: const Duration(milliseconds: 500),
    //             opacity: 0.0,
    //             child: w)
    //         : AnimatedOpacity(
    //             duration: const Duration(milliseconds: 500),
    //             opacity: 1.0,
    //             child: w));

    return w;
  }

  Widget _getHtmlHeader(
      BuildContext context,
      List<DropdownMenuItem<String>> dictionaries,
      Map<String, GlobalKey<State<StatefulWidget>>> dicsToKeys,
      Article article) {
    return Container(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
        height: 30.0,
        decoration: BoxDecoration(
            backgroundBlendMode: BlendMode.srcOver,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.6, 1],
              colors: [
                Theme.of(context).cardColor,
                Theme.of(context).cardColor.withAlpha(0)
              ],
            )),
        alignment: Alignment.bottomRight,
        child: _DictionarySelector(
            dictionaries: dictionaries,
            dicsToKeys: dicsToKeys,
            scrollController: widget.scrollController,
            dictionary: article.dictionaryName));
  }

  SliverToBoxAdapter _getSliverWithHtml(BuildContext context, Article article,
      Map<String, GlobalKey<State<StatefulWidget>>> dicsToKeys) {
    return SliverToBoxAdapter(
        child: Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: Html(
        //sw: globalSw,
        contextMenuBuilder:
            (BuildContext context, EditableTextState editableTextState) {
          return TextSelectionToolbar(
            toolbarBuilder: (context, child) => Material(
              borderRadius: const BorderRadius.all(Radius.circular(5.0)),
              color: ownTheme(context).textSelectionPopupColor,
              child: child,
            ),
            anchorAbove: editableTextState.contextMenuAnchors.primaryAnchor,
            anchorBelow: editableTextState.contextMenuAnchors.primaryAnchor,
            children: [
              IconButton(
                  highlightColor: Colors.blue,
                  icon: const Icon(Icons.copy),
                  onPressed: () => editableTextState
                      .copySelection(SelectionChangedCause.toolbar)),
              IconButton(
                  icon: const Icon(Icons.search_rounded),
                  onPressed: () {
                    widget.showAnotherWord?.call(editableTextState
                        .currentTextEditingValue.selection
                        .textInside(
                            editableTextState.currentTextEditingValue.text));
                  })
            ],
          );
        },

        useIsolate: !kIsWeb,
        isolatePool: !kIsWeb ? pool : null,
        data: article.article,
        onLinkTap: (String? url) {
          if (url != null && url.isNotEmpty) {
            widget.showAnotherWord?.call(url);
          }
        },
        onBuilt: () => dicsToKeys.length == ++_builtCounter
            ? debugPrint(
                'Html.built, # $_builtCounter, ${_globalSw.elapsedMilliseconds}ms')
            : {},
        onLaidOut: () {
          if (dicsToKeys.length == ++_laidoutCounter &&
              !widget.offstageCompleter.isCompleted) {
            debugPrint(
                'Html.laidout, # $_laidoutCounter, ${_globalSw.elapsedMilliseconds}ms');
            widget.offstageCompleter.complete(true);
          }
        },
        style: {
          'a': Style(
            color: Theme.of(context).colorScheme.secondary,
            fontSize: const FontSize(20),
            fontStyle: FontStyle.italic,
            fontFamily: "Tinos",
          ),
          'i': Style(
            //color: Colors.teal[100],
            fontSize: const FontSize(20),
            fontStyle: FontStyle.italic,
            fontFamily: "Tinos",
          ),
          'span': Style(
            color: ownTheme(context).spanColor,
            fontSize: const FontSize(20),
            fontFamily: "Tinos",
            fontStyle: FontStyle.italic,
          ),
          'div': Style(
              padding: const EdgeInsets.all(0),
              fontFamily: "Tinos",
              fontSize: const FontSize(20)),
        },
      ),
    ));
  }
}

class _DictionarySelector extends StatelessWidget {
  const _DictionarySelector(
      {required this.dictionaries,
      required this.dicsToKeys,
      required this.scrollController,
      this.dictionary,
      super.key});

  final List<DropdownMenuItem<String>> dictionaries;
  final Map<String, GlobalKey> dicsToKeys;
  final ScrollController scrollController;
  final String? dictionary;

  @override
  Widget build(BuildContext context) {
    Widget w = DropdownButton(
      // dropdownColor: Theme.of(context).scaffoldBackgroundColor,
      iconSize: 0,
      underline: const SizedBox(),
      elevation: 0,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      iconEnabledColor: Theme.of(context).iconTheme.color,
      alignment: Alignment.centerRight,
      isDense: true,
      items: dictionaries,
      value: dictionary,
      onChanged: (v) {
        var key = dicsToKeys[v];
        if (key != null) {
          scrollController.position.ensureVisible(
              key.currentContext!.findRenderObject()!,
              duration: const Duration(milliseconds: 300));
        }
      },
    );

    // Don't highlisght first item when clicking dropdown in the bottom
    if (dictionary == null) {
      w = Theme(
          data: Theme.of(context)
              .copyWith(focusColor: Theme.of(context).canvasColor),
          child: w);
    }

    return w;
  }
}

/// Hack for cached widget. When returning caceched version of WordArticles there
/// was scroll controller exception due to more than one client, for some reasons
/// scroll controller was attached twice. Made this version in order to call
/// detach() for old position in attach() should there be any possition attached
/// It will only work if navigating forward, navigating back and comming accross the same cached widget will fail (should there not be logic removing from history stack duplicate routes when opening same article multiple times)
class SinglePositionScrollController extends ScrollController {
  @override
  void attach(ScrollPosition position) {
    if (positions.isNotEmpty) {
      if (positions.contains(positions.first)) {
        detach(positions.first);
      }
    }
    super.attach(position);
  }
}

class WordArticlesCache {
  /// As soon as number of items in the cache is above - remove old items
  static const _cachePurgeThreshold = 10;
  static const _cacheItemsToPurge = 5;
  static const _cacheEnabled = true;

  static final LinkedHashMap<String, Widget> _cache =
      LinkedHashMap<String, Widget>();

  static void invalidateCache([bool delayed = false]) {
    if (_cache.isNotEmpty) {
      if (!delayed) {
        _cache.clear();
        debugPrint('WordArtciles widget cache invalidated');
      }
    }
  }

  static void _addItemToCache(String key, Widget value) {
    _cache[key] = value;
    if (_cache.length >= _cachePurgeThreshold) {
      Future.delayed(const Duration(milliseconds: 777), () {
        var keys = _cache.keys.take(_cacheItemsToPurge).toList();
        for (var k in keys) {
          _cache.remove(k);
        }
        debugPrint('WordArtciles widget cache purged');
      });
    }
  }

  static bool _cacheItemExists(String key) => _cache.keys.contains(key);

  static Widget _getCacheItem(String key) => _cache[key]!;
}
