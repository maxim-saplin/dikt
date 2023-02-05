import 'dart:async';
import 'package:after_layout/after_layout.dart';
import 'package:dikt/common/helpers.dart';
import 'package:dikt/common/isolate_pool.dart';
import 'package:dikt/ui/themes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dikt/models/master_dictionary.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

import '../routes.dart';

// Started when top level widget build() is called and used to measure article widgets layouts - essentialy time to dispolay
Stopwatch globalSw = Stopwatch();
final Map<String, Widget> _cache = {};

class WordArticles extends StatelessWidget {
  WordArticles(
      {Key? key,
      required this.articles,
      required this.word,

      /// Callback to call in order to navigate to a word within an article
      this.showAnotherWord})
      : super(key: key);

  final ScrollController scrollController = ScrollController();

  final Future<List<Article>>? articles;
  final String word;
  final Function(String word)? showAnotherWord;

  @override
  Widget build(BuildContext context) {
    Widget w = const SizedBox();

    // TODO, add proper caching with invalidation and freeing up old/first N added entries
    if (_cache.keys.contains(word)) {
      w = _cache[word]!;
    } else {
      globalSw.reset();
      globalSw.start();
      // List of dictionaries is only known when all articles are loaded and correponding future is completed, using this completer to trigger UI for dictionaries
      var dicsCompleter = Completer<
          Tuple<List<DropdownMenuItem<String>>, Map<String, GlobalKey>>>();

      if (articles == null) {
        return const SizedBox();
      }

      w = Stack(children: [
        ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            child: ColoredBox(
                color: Theme.of(context).cardColor,
                child: Stack(children: [
                  // Article list
                  _FuturedArticles(
                      articles: articles!,
                      dicsCompleter: dicsCompleter,
                      scrollController: scrollController,
                      showAnotherWord: showAnotherWord),
                  // Title with selectable text - word
                  Container(
                      padding: const EdgeInsets.fromLTRB(18, 15, 18, 0),
                      color: Theme.of(context).cardColor,
                      height: 39.0,
                      width: 1000,
                      child: SelectableText(
                        word,
                        style: Theme.of(context).textTheme.headlineSmall,
                      )),
                ]))),
        // Bottom buttons
        Positioned(
          bottom: 0.0,
          left: 0.0,
          right: 0.0,
          height: 50,
          child: Container(
              color: Theme.of(context).cardColor,
              child: Flex(
                  direction: Axis.horizontal,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Back button
                    Expanded(
                        flex: 1,
                        child: TextButton(
                          onPressed: () {
                            // Due to cachning and routing this context might be bad
                            //Navigator.of(context).pop();
                            Routes.goBack();
                          },
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Theme.of(context).iconTheme.color,
                            size: 18,
                          ),
                        )),
                    // Dictionary selector
                    Expanded(
                        flex: 1,
                        child: Stack(alignment: Alignment.center, children: [
                          const Icon(
                            Icons.launch_rounded,
                            size: 20,
                          ),
                          FutureBuilder<
                                  Tuple<List<DropdownMenuItem<String>>,
                                      Map<String, GlobalKey>>>(
                              future: dicsCompleter.future,
                              builder: (c, s) => s.hasData && s.data != null
                                  ?
                                  // TODO - fix button being too narrow and icon not covering the click area (e.g. wide window)
                                  // try Actions https://stackoverflow.com/questions/57529394/how-to-open-dropdownbutton-when-other-widget-is-tapped-in-flutter
                                  OverflowBox(
                                      alignment: Alignment.centerRight,
                                      maxWidth: 500,
                                      child: SizedBox(
                                          child: _DictionarySelector(
                                              dictionaries: s.data!.value1,
                                              dicsToKeys: s.data!.value2,
                                              scrollController:
                                                  scrollController)))
                                  : const SizedBox())
                        ])),
                  ])),
        )
      ]);

      _cache[word] = w;
    }

    return w;
  }
}

/// Awaits for articles from Futures and passes their contents for rendering
class _FuturedArticles extends StatelessWidget {
  const _FuturedArticles(
      {Key? key,
      required this.articles,
      required this.dicsCompleter,
      required this.scrollController,
      required this.showAnotherWord})
      : super(key: key);

  static EdgeInsets headerInsets = const EdgeInsets.fromLTRB(0, 30, 0, 50);

  final Future<List<Article>> articles;
  final Completer<Tuple<List<DropdownMenuItem<String>>, Map<String, GlobalKey>>>
      dicsCompleter;
  final ScrollController scrollController;
  final Function(String word)? showAnotherWord;

  @override
  Widget build(BuildContext context) {
    var w = FutureBuilder<List<Article>>(
      //future: Future.delayed(const Duration(seconds: 2), () => articles),
      future: articles,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _FuturedArticleBodies(snapshot.data ?? [], dicsCompleter,
              scrollController, showAnotherWord);
        }
        return const _Empty();
      },
    );

    //debugPrint('_FuturedArticle built ${sw.elapsedMilliseconds}ms');
    return w;
  }
}

// TODO, get rid of empty, to avoid jump better show UI when ready (prepared off-stage) rather than display empty word header and nav bar with empty space in between, dot in the center might be a better way for empty UI
/// Empty placeholder to show smth
class _Empty extends StatelessWidget {
  const _Empty({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: _FuturedArticles.headerInsets,
        child: Container(
            color: Theme.of(context).cardColor,
            width: 10000,
            height: 40,
            child: const SizedBox()));
  }
}

/// Each individual article is built via Html renderer which potentially can use external isolate. Time to render/layout is measured and printed in debug log
class _FuturedArticleBodies extends StatefulWidget {
  const _FuturedArticleBodies(this.articles, this.bottomDictionariesCompleter,
      this.scrollController, this.showAnotherWord);
  final List<Article> articles;
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
        '_FuturedArticleBody laidout ${sw.elapsedMilliseconds}ms, total ${globalSw.elapsedMilliseconds}');
  }

  final UniqueKey _scrollKey = UniqueKey();

  final _offstageCompleter = Completer();

  int _builtCounter = 0;
  int _laidoutCounter = 0;

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

    var dicsToKeys = <String, GlobalKey>{};

    // Aggregate all dictionaries in bottom nav bar
    if (!widget.bottomDictionariesCompleter.isCompleted) {
      widget.bottomDictionariesCompleter
          .complete(Tuple(dictionaries, dicsToKeys));
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
                var key = GlobalKey();
                dicsToKeys[article.dictionaryName] = key;
                return SliverStickyHeader(
                  key: key,
                  header: _getHtmlHeader(
                      context, dictionaries, dicsToKeys, article),
                  // Html widget has future builder inside and display empty UI when rendering is not ready but also provides onLaidOut callback to let know that future is received and view is rendered
                  sliver: _getSliverWithHtml(context, article, dicsToKeys),
                );
              }).toList(),
            )));

    // debugPrint(
    //     '_FuturedArticleBody built ${sw.elapsedMilliseconds}ms, total ${globalSw.elapsedMilliseconds}');

    // TODO, check multiple ductionary article works fine, previously there was Offstage wrapping Html widgets assuming is should help with all Html widgets to be displayed at the same time when all are ready

    return FutureBuilder(
        future: _offstageCompleter.future,
        builder: (c, s) => !s.hasData
            // Ussing Offstage to prepaer all article and present them in one frame when all are ready
            // Using stack and _Empty to avoid any jumps and keep width of the widget occupied
            ? Stack(
                children: [Offstage(offstage: true, child: w), const _Empty()])
            : Offstage(offstage: false, child: w));

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

    // return w;
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
              color: Theme.of(context).colorScheme.primary,
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
                'Html.built, # $_builtCounter, ${globalSw.elapsedMilliseconds}ms')
            : {},
        onLaidOut: () {
          if (dicsToKeys.length == ++_laidoutCounter &&
              !_offstageCompleter.isCompleted) {
            debugPrint(
                'Html.laidout, # $_laidoutCounter, ${globalSw.elapsedMilliseconds}ms');
            _offstageCompleter.complete(true);
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
      this.dictionary});

  final List<DropdownMenuItem<String>> dictionaries;
  final Map<String, GlobalKey> dicsToKeys;
  final ScrollController scrollController;
  final String? dictionary;

  @override
  Widget build(BuildContext context) {
    Widget w = DropdownButton(
      dropdownColor: Theme.of(context).scaffoldBackgroundColor,
      iconSize: 0,
      underline: const SizedBox(),
      iconEnabledColor: Theme.of(context).iconTheme.color,
      alignment: Alignment.centerRight,
      isDense: true,
      items: dictionaries,
      value: dictionary,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
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
              .copyWith(focusColor: Theme.of(context).scaffoldBackgroundColor),
          child: w);
    }

    return w;
  }
}
