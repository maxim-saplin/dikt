import 'package:flutter/material.dart';
import 'package:dikt/models/masterDictionary.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

class WordArticles extends StatelessWidget {
  const WordArticles(
      {Key key,
      @required this.articles,
      @required this.word,
      this.showAnotherWord})
      : super(key: key);

  final Future<List<Article>> articles;
  final String word;
  final Function(String word) showAnotherWord;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      FutureBuilder(
        future: articles,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var list = snapshot.data as List<Article>;
            return CustomScrollView(
              semanticChildCount: list.length,
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              slivers: list
                  .map((article) => SliverStickyHeader(
                        header: Align(
                            child: Container(
                          padding: EdgeInsets.all(12),
                          height: 48.0,
                          color: Theme.of(context).cardColor,
                          child: Text(article.dictionaryName,
                              style: Theme.of(context).textTheme.subtitle2),
                          alignment: Alignment.centerRight,
                        )),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((context, i) {
                            return Padding(
                                padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
                                child: Html(
                                  data: article.article,
                                  onLinkTap: (url) {
                                    if (showAnotherWord != null)
                                      showAnotherWord(url);
                                  },
                                  style: {
                                    "div": Style(
                                        fontFamily: 'sans-serif-light',
                                        padding: EdgeInsets.all(0),
                                        fontSize: FontSize(19)),
                                  },
                                ));
                          }, childCount: 1),
                        ),
                      ))
                  .toList(),
            );
          }
          return Center(child: Text('...'));
        },
      ),
      Container(
          padding: EdgeInsets.all(12),
          height: 48.0,
          child: SelectableText(
            word,
            style: Theme.of(context).textTheme.headline6,
          )),
    ]);
  }
}
