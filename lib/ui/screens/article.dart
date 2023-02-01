import 'package:dikt/ui/adaptive.dart';
import 'package:dikt/ui/elements/menu_buttons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/master_dictionary.dart';
import '../elements/loading_progress.dart';
import '../elements/lookup.dart';
import '../elements/word_articles.dart';

class Content extends StatelessWidget {
  const Content({Key? key, this.word = ''}) : super(key: key);

  final String word;

  @override
  Widget build(BuildContext context) {
    var dictionary = Provider.of<MasterDictionary>(context);
    Future<List<Article>>? articles = dictionary.getArticles(word);

    // TODO, fix blinking when resizing window on macOS
    // TODO, fix blinking when switching words in two pane mode
    // TODO, fix navigatoin to another article via a link in an article
    return AdaptiveSplitView(
        ifOnePane: (c, add) => add(Align(
            alignment: Alignment.bottomCenter,
            child: WordArticles(articles: articles, word: word))),
        ifTwoPanes: (c, add) => add(
            Stack(children: const [
              Lookup(searchBarTopRounded: false),
              EmptyHints(showDictionaryStats: false, showSearchBarHint: true)
            ]),
            Stack(children: [
              Center(
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 38, 0, 0),
                      child: WordArticles(articles: articles, word: word))),
              const TopButtons()
            ])));
  }
}
