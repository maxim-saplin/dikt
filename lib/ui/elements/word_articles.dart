import 'dart:async';

import 'package:dikt/common/helpers.dart';
import 'package:dikt/ui/themes.dart';
import 'package:flutter/material.dart';
import 'package:dikt/models/master_dictionary.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

class WordArticles extends StatelessWidget {
  WordArticles(
      {Key? key,
      required this.articles,
      required this.word,
      this.showAnotherWord})
      : super(key: key);

  final List<Future<Article>> articles;
  final String word;
  final Function(String word)? showAnotherWord;
  final ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    var dicsCompleter = Completer<
        Tuple<List<DropdownMenuItem<String>>, Map<String, GlobalKey>>>();

    //     var dictionaries = list
    //     .map((a) => DropdownMenuItem<String>(
    //         alignment: Alignment.centerRight,
    //         child: Text(
    //           a.dictionaryName,
    //           style: Theme.of(context).textTheme.subtitle2,
    //         ),
    //         value: a.dictionaryName))
    //     .toList();

    // var dicsToKeys = Map<String, GlobalKey>();

    // if (!dicsCompleter.isCompleted) {
    //   dicsCompleter.complete(Tuple(dictionaries, dicsToKeys));
    // }

    return Stack(children: [
      ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          child: Stack(children: [
            FutureBuilder(
                future: Future.wait(articles),
                builder: (c, s) => s.hasData
                    ? Padding(
                        padding: EdgeInsets.fromLTRB(0, 30, 0, 50),
                        child: PrimaryScrollController(
                            controller: scrollController,
                            child: Scrollbar(
                                child: CustomScrollView(
                              physics: BouncingScrollPhysics(),
                              semanticChildCount: articles.length,
                              scrollDirection: Axis.vertical,
                              shrinkWrap: true,
                              slivers: articles.map((article) {
                                // var key = GlobalKey();
                                // dicsToKeys[article.dictionaryName] = key;
                                return SliverStickyHeader(
                                  key: key,
                                  header: Align(
                                      child: Container(
                                    padding: EdgeInsets.fromLTRB(18, 0, 18, 0),
                                    height: 30.0,
                                    color: Theme.of(context).cardColor,
                                    child: Text('TEST'),

                                    // _DictionarySelector(
                                    //     dictionaries: dictionaries,
                                    //     dicsToKeys: dicsToKeys,
                                    //     scrollController: scrollController,
                                    //     dictionary: article.dictionaryName),
                                    alignment: Alignment.bottomRight,
                                  )),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                        (context, i) => FutureBuilder<Article>(
                                            future: article,
                                            builder: (c, s) => s.hasData &&
                                                    s.data != null
                                                ? Container(
                                                    color: Theme.of(context)
                                                        .cardColor,
                                                    padding:
                                                        EdgeInsets.fromLTRB(
                                                            18, 0, 18, 10),
                                                    child: Html(
                                                      data: s.data!.article,
                                                      onLinkTap: (String? url) {
                                                        if (showAnotherWord !=
                                                            null)
                                                          showAnotherWord!(
                                                              url!);
                                                      },
                                                      style: {
                                                        "a": Style(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .secondary,
                                                            fontSize:
                                                                FontSize(18),
                                                            fontStyle: FontStyle
                                                                .italic,
                                                            fontFamily:
                                                                "OpenSans"),
                                                        "span": Style(
                                                            color: ownTheme(
                                                                    context)
                                                                .spanColor,
                                                            fontSize:
                                                                FontSize(18),
                                                            fontStyle: FontStyle
                                                                .italic,
                                                            fontFamily:
                                                                "OpenSans"),
                                                        "div": Style(
                                                            padding:
                                                                EdgeInsets.all(
                                                                    0),
                                                            //fontFamily: "OpenSans",
                                                            fontSize:
                                                                FontSize(18)),
                                                      },
                                                    ))
                                                : Container(
                                                    color: Theme.of(context)
                                                        .cardColor,
                                                    height: 30,
                                                    padding:
                                                        EdgeInsets.fromLTRB(
                                                            18, 0, 18, 10),
                                                    child: SizedBox())),
                                        childCount: 1),
                                  ),
                                );
                              }).toList(),
                            ))))
                    : SizedBox()),
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
      Positioned(
        child: Container(
            color: Theme.of(context).cardColor,
            child: Flex(
                direction: Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
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
                  Expanded(
                      flex: 1,
                      child: FutureBuilder<
                              Tuple<List<DropdownMenuItem<String>>,
                                  Map<String, GlobalKey>>>(
                          future: dicsCompleter.future,
                          builder: (c, s) => s.hasData && s.data != null
                              ? Stack(alignment: Alignment.center, children: [
                                  Icon(
                                    Icons.launch_rounded,
                                    size: 20,
                                  ),
                                  // TODO - fix button being to narrow and icon not covering the click area (e.g. wide window)
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
                                ])
                              : SizedBox())),
                ])),
        bottom: 0.0,
        left: 0.0,
        right: 0.0,
        height: 50,
      )
    ]);
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
          // Scrollable.ensureVisible(key.currentContext!,
          //     duration: Duration(milliseconds: 300));
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
