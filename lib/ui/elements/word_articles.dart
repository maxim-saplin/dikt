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

// Started when top level widget build() is called and used to measure article widgets layouts - essentialy time to dispolay
Stopwatch globalSw = Stopwatch();

class WordArticles extends StatelessWidget {
  WordArticles(
      {Key? key,
      required this.articles,
      required this.word,
      this.showAnotherWord})
      : super(key: key);

  final ScrollController scrollController = ScrollController();

  final Future<List<Article>> articles;
  final String word;
  final Function(String word)? showAnotherWord;

  @override
  Widget build(BuildContext context) {
    globalSw.reset();
    globalSw.start();
    var dicsCompleter = Completer<
        Tuple<List<DropdownMenuItem<String>>, Map<String, GlobalKey>>>();

    var w = Stack(children: [
      ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          child: Stack(children: [
            // Article list
            _FuturedArticles(
                articles: articles,
                dicsCompleter: dicsCompleter,
                scrollController: scrollController,
                showAnotherWord: showAnotherWord),
            // Title with selectable text - word
            Container(
                padding: EdgeInsets.fromLTRB(18, 15, 18, 0),
                color: Theme.of(context).cardColor,
                height: 39.0,
                width: 1000,
                child: SelectableText(
                  word,
                  style: Theme.of(context).textTheme.headline6,
                )),
          ])),
      // Bottom buttons
      Positioned(
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
                          Navigator.of(context).pop();
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
                        Icon(
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
                                : SizedBox())
                      ])),
                ])),
        bottom: 0.0,
        left: 0.0,
        right: 0.0,
        height: 50,
      )
    ]);

    return w;
  }
}

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

  Widget build(BuildContext context) {
    var w = FutureBuilder(
      future: articles,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _FuturedArticleBody(
              snapshot, dicsCompleter, scrollController, showAnotherWord);
        }
        return _Empty();
      },
    );

    //print('_FuturedArticle built ${sw.elapsedMilliseconds}ms');
    return w;
  }
}

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
            child: SizedBox()));
  }
}

class _FuturedArticleBody extends StatefulWidget {
  _FuturedArticleBody(this.snapshot, this.dicsCompleter, this.scrollController,
      this.showAnotherWord);
  final AsyncSnapshot<Object?> snapshot;
  final Completer<
      Tuple<List<DropdownMenuItem<String>>,
          Map<String, GlobalKey<State<StatefulWidget>>>>> dicsCompleter;
  final ScrollController scrollController;
  final Function(String word)? showAnotherWord;

  @override
  State<_FuturedArticleBody> createState() => _FuturedArticleBodyState();
}

class _FuturedArticleBodyState extends State<_FuturedArticleBody>
    with AfterLayoutMixin<_FuturedArticleBody> {
  var sw = Stopwatch();

  @override
  void afterFirstLayout(BuildContext context) {
    print(
        '_FuturedArticleBody laidout ${sw.elapsedMilliseconds}ms, total ${globalSw.elapsedMilliseconds}');
  }

  //bool _buildingHtmlComplete = false;
  UniqueKey scrollKey = UniqueKey();

  var _offstageCompleter = Completer();

  // @override
  // void initState() {
  //   super.initState();
  //   _buildingHtmlComplete = false;
  // }

  @override
  Widget build(BuildContext context) {
    sw.reset();
    sw.start();
    var list = widget.snapshot.data as List<Article>;

    var dictionaries = list
        .map((a) => DropdownMenuItem<String>(
            alignment: Alignment.centerRight,
            child: Text(
              a.dictionaryName,
              style: Theme.of(context).textTheme.subtitle2,
            ),
            value: a.dictionaryName))
        .toList();

    var dicsToKeys = Map<String, GlobalKey>();

    if (!widget.dicsCompleter.isCompleted) {
      widget.dicsCompleter.complete(Tuple(dictionaries, dicsToKeys));
    }

    var builtCounter = 0;
    var laidoutCounter = 0;

    Widget w = Padding(
        key: scrollKey,
        padding: _FuturedArticles.headerInsets,
        child: PrimaryScrollController(
            controller: widget.scrollController,
            child: Scrollbar(
                child: CustomScrollView(
              physics: BouncingScrollPhysics(),
              semanticChildCount: list.length,
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              slivers: list.map((article) {
                var key = GlobalKey();
                dicsToKeys[article.dictionaryName] = key;
                return SliverStickyHeader(
                  key: key,
                  header: Align(
                      child: Container(
                    padding: EdgeInsets.fromLTRB(18, 0, 18, 0),
                    height: 30.0,
                    color: Theme.of(context).cardColor,
                    child: _DictionarySelector(
                        dictionaries: dictionaries,
                        dicsToKeys: dicsToKeys,
                        scrollController: widget.scrollController,
                        dictionary: article.dictionaryName),
                    alignment: Alignment.bottomRight,
                  )),
                  sliver: SliverToBoxAdapter(
                      child: Container(
                    color: Theme.of(context).cardColor,
                    padding: EdgeInsets.fromLTRB(18, 0, 18, 10),
                    child: Html(
                      //sw: globalSw,
                      useIsolate: !kIsWeb,
                      isolatePool: !kIsWeb ? pool : null,
                      data: article.article,
                      onLinkTap: (String? url) {
                        if (widget.showAnotherWord != null)
                          widget.showAnotherWord!(url!);
                      },
                      onBuilt: () => dicsToKeys.length == ++builtCounter
                          ? print(
                              'Html.built, # ${builtCounter}, ${globalSw.elapsedMilliseconds}ms')
                          : {},
                      onLaidOut: () {
                        if (dicsToKeys.length == ++laidoutCounter) {
                          print(
                              'Html.laidout, # ${laidoutCounter}, ${globalSw.elapsedMilliseconds}ms');
                          _offstageCompleter.complete(true);
                        }
                      },
                      style: {
                        'a': Style(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: FontSize(20),
                          fontStyle: FontStyle.italic,
                          fontFamily: "Tinos",
                        ),
                        'i': Style(
                          //color: Colors.teal[100],
                          fontSize: FontSize(20),
                          fontStyle: FontStyle.italic,
                          fontFamily: "Tinos",
                        ),
                        'span': Style(
                          color: ownTheme(context).spanColor,
                          fontSize: FontSize(20),
                          fontFamily: "Tinos",
                          fontStyle: FontStyle.italic,
                        ),
                        'div': Style(
                            padding: EdgeInsets.all(0),
                            fontFamily: "Tinos",
                            fontSize: FontSize(20)),
                      },
                    ),
                  )),
                );
              }).toList(),
            ))));
    // print(
    //     '_FuturedArticleBody built ${sw.elapsedMilliseconds}ms, total ${globalSw.elapsedMilliseconds}');

    return FutureBuilder(
        future: _offstageCompleter.future,
        builder: (c, s) => !s.hasData
            ? Stack(children: [Offstage(child: w, offstage: true), _Empty()])
            : AnimatedScale(
                duration: Duration(milliseconds: 2660), scale: 1.0, child: w));
  }
}

class _DictionarySelector extends StatelessWidget {
  const _DictionarySelector(
      {required this.dictionaries,
      required this.dicsToKeys,
      required this.scrollController,
      this.dictionary});

  final List<DropdownMenuItem<String>> dictionaries;
  final Map<String, GlobalKey<State<StatefulWidget>>> dicsToKeys;
  final ScrollController scrollController;
  final String? dictionary;

  @override
  Widget build(BuildContext context) {
    Widget w = DropdownButton(
      dropdownColor: Theme.of(context).scaffoldBackgroundColor,
      iconSize: 0,
      underline: SizedBox(),
      iconEnabledColor: Theme.of(context).iconTheme.color,
      alignment: Alignment.centerRight,
      isDense: true,
      items: dictionaries,
      value: dictionary,
      borderRadius: BorderRadius.all(Radius.circular(8)),
      onChanged: (v) {
        var key = dicsToKeys[v];
        if (key != null) {
          scrollController.position.ensureVisible(
              key.currentContext!.findRenderObject()!,
              duration: Duration(milliseconds: 300));
        }
      },
    );

    // Don't highlisght first item when clicking dropdown in the bottom
    if (dictionary == null) {
      w = Theme(
          child: w,
          data: Theme.of(context)
              .copyWith(focusColor: Theme.of(context).scaffoldBackgroundColor));
    }

    return w;
  }
}
