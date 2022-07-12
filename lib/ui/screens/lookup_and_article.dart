import 'package:dikt/models/dictionary_manager.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../ui/screens/lookup.dart';
import '../elements/menu_buttons.dart';
import '../elements/loading_progress.dart';
import '../elements/word_articles.dart';
import '../../models/master_dictionary.dart';
import '../../common/i18n.dart';

class LookupAndArticle extends StatelessWidget {
  final String? word;

  const LookupAndArticle({Key? key, this.word}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var route = ModalRoute.of(context)!.settings;

    // if (!(route.name == Routes.showArticle ||
    //     route.name == Routes.showArticleWide)) {
    //   return const SizedBox();
    // }

    var word = (route.arguments ?? '') as String;
    var dictionary = Provider.of<MasterDictionary>(context);
    var manager = Provider.of<DictionaryManager>(context);
    Future<List<Article>>? articles =
        word.isEmpty ? null : getArticles(context, word);

    return Stack(children: [
      Row(children: [
        const Expanded(
          flex: 1,
          child: Lookup(narrow: false),
        ),
        Expanded(
            flex: 2,
            child: Container(
                color: Theme.of(context).cardColor,
                child: Stack(children: [
                  const DictionaryIndexing(),
                  ((word.isEmpty)
                      ? Center(
                          child: Text(
                              dictionary.isPartiallyLoaded
                                  ? ('${dictionary.totalEntries == 0 ? '↗↗↗\n${'Try adding dictionaries'.i18n}\n\n' : '${manager.dictionariesEnabled.where((d) => d.isLoaded).length} ${'dictionaries'.i18n}\n\n'}${dictionary.totalEntries} ${'entries'.i18n}')
                                  : '',
                              textAlign: TextAlign.center))
                      : Center(
                          child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 38, 0, 0),
                              child: WordArticles(
                                  articles: articles,
                                  word: word,
                                  showAnotherWord: (word) =>
                                      showArticle(context, word, false))))),
                  const TopButtons()
                ])))
      ]),
      const DictionaryLoading()
    ]);
  }
}
