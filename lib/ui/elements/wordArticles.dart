import 'package:flutter/material.dart';
import 'package:dikt/models/masterDictionary.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

class WordArticles extends StatelessWidget {
  WordArticles(
      {Key key,
      @required this.articles,
      @required this.word,
      this.showAnotherWord})
      : super(key: key);

  final Future<List<Article>> articles;
  final String word;
  final Function(String word) showAnotherWord;
  final ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Center(
          child: Stack(children: [
        FutureBuilder(
          future: articles,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              var list = snapshot.data as List<Article>;
              return Padding(
                  padding: EdgeInsets.fromLTRB(0, 25, 0, 50),
                  child: PrimaryScrollController(
                      controller: scrollController,
                      child: Scrollbar(
                          child: CustomScrollView(
                        physics: BouncingScrollPhysics(),
                        semanticChildCount: list.length,
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        slivers: list
                            .map((article) => SliverStickyHeader(
                                  header: Align(
                                      child: Container(
                                    padding: EdgeInsets.fromLTRB(18, 0, 18, 0),
                                    height: 30.0,
                                    color: Theme.of(context).cardColor,
                                    child: Text(article.dictionaryName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle2),
                                    alignment: Alignment.bottomRight,
                                  )),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                        (context, i) {
                                      return Padding(
                                          padding: EdgeInsets.fromLTRB(
                                              10, 0, 10, 10),
                                          child: Html(
                                            data: article.article,
                                            onLinkTap: (url) {
                                              if (showAnotherWord != null)
                                                showAnotherWord(url);
                                            },
                                            style: {
                                              "div": Style(
                                                  fontFamily:
                                                      'sans-serif-light',
                                                  padding: EdgeInsets.all(0),
                                                  fontSize: FontSize(19)),
                                            },
                                          ));
                                    }, childCount: 1),
                                  ),
                                ))
                            .toList(),
                      ))));
            }
            return Padding(
                padding: EdgeInsets.fromLTRB(0, 25, 0, 50),
                child: Container(
                    width: 10000,
                    height: 40,
                    child: Align(
                      child: Text('...'),
                      alignment: Alignment.center,
                    )));
          },
        ),
        Container(
            padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
            color: Theme.of(context).cardColor,
            height: 34.0,
            width: 1000,
            child: SelectableText(
              word,
              style: Theme.of(context).textTheme.headline6,
            )),
      ])),
      Positioned(
        child: Container(
            padding: EdgeInsets.only(left: 30, right: 30),
            color: Theme.of(context).scaffoldBackgroundColor.withAlpha(105),
            child: FlatButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('▽'),
            )),
        bottom: 0.0,
        left: 0.0,
        right: 00.0,
        height: 50,
      )
    ]);
  }
}
