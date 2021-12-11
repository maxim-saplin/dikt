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

  final Future<List<Article>> articles;
  final String word;
  final Function(String word)? showAnotherWord;
  final ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          child: Stack(children: [
            FutureBuilder(
              future: articles,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var list = snapshot.data as List<Article>;

                  var dictionaries = list
                      .map((a) => DropdownMenuItem<String>(
                          alignment: Alignment.centerRight,
                          child: Text(
                            a.dictionaryName,
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                          value: a.dictionaryName))
                      .toList();

                  // var keys = List<GlobalKey>.generate(
                  //     list.length, (index) => GlobalKey());
                  // var i = 0;

                  var dicsToKeys = Map<String, GlobalKey>();

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
                                  child: DropdownButton(
                                    iconSize: 0,
                                    underline: SizedBox(),
                                    alignment: Alignment.centerRight,
                                    isDense: true,
                                    items: dictionaries,
                                    value: article.dictionaryName,
                                    onChanged: (v) {
                                      var key = dicsToKeys[v];
                                      if (key != null) {
                                        Scrollable.ensureVisible(
                                            key.currentContext!,
                                            duration:
                                                Duration(milliseconds: 300));
                                      }
                                    },
                                  ),
                                  // Text(article.dictionaryName!,
                                  //     style: Theme.of(context)
                                  //         .textTheme
                                  //         .subtitle2),
                                  alignment: Alignment.bottomRight,
                                )),
                                sliver: SliverList(
                                  delegate:
                                      SliverChildBuilderDelegate((context, i) {
                                    return Container(
                                        color: Theme.of(context).cardColor,
                                        padding:
                                            EdgeInsets.fromLTRB(18, 0, 18, 10),
                                        child: Html(
                                          data: article.article,
                                          onLinkTap: (String? url) {
                                            if (showAnotherWord != null)
                                              showAnotherWord!(url!);
                                          },
                                          style: {
                                            "div": Style(
                                                // fontFamily:
                                                //     'sans-serif-light',
                                                padding: EdgeInsets.all(0),
                                                fontSize: FontSize(19)),
                                          },
                                        ));
                                  }, childCount: 1),
                                ),
                              );
                            }).toList(),
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
                padding: EdgeInsets.fromLTRB(18, 10, 18, 0),
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
            //padding: EdgeInsets.only(left: 30, right: 30),
            color: Theme.of(context).cardColor,
            //color: Theme.of(context).scaffoldBackgroundColor.withAlpha(105),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              iconSize: 20,
              //hoverColor: The,
              icon: Icon(Icons.arrow_back_ios_new),
              //child: Text('▽'),
            )),
        bottom: 0.0,
        left: 0.0,
        right: 00.0,
        height: 50,
      )
    ]);
  }
}
