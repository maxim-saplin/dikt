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

  LookupAndArticle(this.word);

  @override
  Widget build(BuildContext context) {
    var word = ModalRoute.of(context)!.settings.arguments;
    var dictionary = Provider.of<MasterDictionary>(context);
    var manager = Provider.of<DictionaryManager>(context);

    return Stack(children: [
      Row(children: [
        Expanded(
          child: Lookup(false),
          flex: 1,
        ),
        Expanded(
            child: Container(
                color: Theme.of(context).cardColor,
                child: Stack(children: [
                  DictionaryIndexing(),
                  ((word == null || word == '')
                      ? Center(
                          child: Text(
                              dictionary.isPartiallyLoaded
                                  ? ((dictionary.totalEntries == 0
                                          ? '↗↗↗\n' +
                                              'Try adding dictionaries'.i18n +
                                              '\n\n'
                                          : manager.dictionariesEnabled
                                                  .where((d) => d.isLoaded)
                                                  .length
                                                  .toString() +
                                              ' ' +
                                              'dictionaries'.i18n +
                                              '\n\n') +
                                      dictionary.totalEntries.toString() +
                                      ' ' +
                                      'entries'.i18n)
                                  : '',
                              textAlign: TextAlign.center))
                      : Center(
                          child: Padding(
                              padding: EdgeInsets.fromLTRB(0, 38, 0, 0),
                              child: WordArticles(
                                  articles: getArticlesAndUpdateHistory(
                                      context, word as String),
                                  word: word,
                                  showAnotherWord: (word) =>
                                      showArticle(context, word, false))))),
                  TopButtons()
                ])),
            flex: 2)
      ]),
      DictionaryLoading()
    ]);
  }
}