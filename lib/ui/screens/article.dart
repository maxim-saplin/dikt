import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/master_dictionary.dart';
import '../elements/loading_progress.dart';
import '../elements/lookup.dart';
import '../elements/menu_buttons.dart';
import '../elements/word_articles.dart';
import '../responsive.dart';
import '../routes.dart';

class Content extends StatelessWidget {
  const Content({Key? key, this.word = ''}) : super(key: key);

  final String word;

  @override
  Widget build(BuildContext context) {
    var dictionary = Provider.of<MasterDictionary>(context);
    Future<List<Article>>? articles = dictionary.getArticles(word);

    return ResponsiveSplitView(
        ifOnePane: (c, add) => add(Stack(children: [
              const Lookup(
                  searchBarTopRounded: false, autoFocusSearchBar: false),
              blurBackground(GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Routes.goBack(),
                  child: Align(
                      alignment: Alignment.bottomCenter,
                      // With this geasture detector swallow tap event that due to some reasons bubbled up and closed article when scrolling animation was active and tap was registered
                      child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {},
                          child: WordArticles(
                              articles: articles,
                              word: word,
                              twoPaneMode: false,
                              showAnotherWord: (word) =>
                                  Routes.showArticle(word))))))
            ])),
        ifTwoPanes: (c, add) => add(
            Stack(children: const [
              Lookup(searchBarTopRounded: false, autoFocusSearchBar: false),
              EmptyHints(showDictionaryStats: false, showSearchBarHint: true)
            ]),
            Stack(children: [
              Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                      color: Theme.of(context).cardColor,
                      padding: const EdgeInsets.fromLTRB(0, 38, 0, 0),
                      child: WordArticles(
                          articles: articles,
                          word: word,
                          twoPaneMode: true,
                          showAnotherWord: (word) =>
                              Routes.showArticle(word)))),
              const TopButtons()
            ])));
  }
}
