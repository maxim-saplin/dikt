import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../models/master_dictionary.dart';
import '../../common/simple_simple_dialog.dart';
import '../../common/i18n.dart';

import '../elements/word_articles.dart';
import '../elements/menu_buttons.dart';
import '../elements/loading_progress.dart';
import '../../models/history.dart';
import '../routes.dart';

class Lookup extends StatelessWidget {
  final bool narrow;

  Lookup(this.narrow);

  @override
  Widget build(BuildContext context) {
    var dictionary = Provider.of<MasterDictionary>(context);
    var history = Provider.of<History>(context, listen: false);

    return Stack(children: [
      narrow ? DictionaryIndexingOrLoading() : Text(''),
      Column(children: [
        !dictionary.isPartiallyLoaded
            ? Expanded(child: Text(''))
            : ((dictionary.isLookupWordEmpty && history.wordsCount < 1) ||
                    dictionary.totalEntries == 0
                ? Expanded(
                    child: Center(
                        child: Padding(
                            padding: EdgeInsets.fromLTRB(0, 100, 0, 0),
                            child: Text(
                              (narrow
                                      ? ((dictionary.totalEntries == 0
                                              ? '↑↑↑\n' +
                                                  'Try adding dictionaries'
                                                      .i18n +
                                                  '\n\n'
                                              : '') +
                                          dictionary.totalEntries.toString() +
                                          ' ' +
                                          'entries'.i18n)
                                      : '') +
                                  (dictionary.totalEntries > 0
                                      ? '\n\n' +
                                          'Type-in text below'.i18n +
                                          '\n↓ ↓ ↓'
                                      : ''),
                              textAlign: TextAlign.center,
                            ))))
                : Expanded(
                    child: Padding(
                        padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                        child: _WordsList(
                          dictionary: dictionary,
                          history: history,
                          narrow: narrow,
                        )))),
        _SearchBar(narrow)
      ]),
      narrow ? TopButtons() : Text(''),
    ]);
  }
}

class _WordsList extends StatelessWidget {
  const _WordsList(
      {required this.dictionary, required this.history, required this.narrow});

  final MasterDictionary dictionary;
  final History history;
  final bool narrow;

  static const int _emptyEntries = 5; //allow to reach top items

  @override
  Widget build(BuildContext context) {
    Widget sv = CustomScrollView(
      physics: BouncingScrollPhysics(),
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return _Entry(index, dictionary, history, narrow);
          },
              childCount: _emptyEntries +
                  (dictionary.isLookupWordEmpty
                      ? history.wordsCount
                      : dictionary.matchesCount)),
        ),
      ],
      semanticChildCount: dictionary.matchesCount,
      scrollDirection: Axis.vertical,
      reverse: true,
    );

    if (!kIsWeb) {
      sv = ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black, Colors.transparent],
            ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height - 200));
          },
          blendMode: BlendMode.dstIn,
          child: sv);
    }

    return sv;
  }
}

class _Entry extends StatelessWidget {
  final int index;
  final MasterDictionary dictionary;
  final History history;
  final bool narrow;

  _Entry(this.index, this.dictionary, this.history, this.narrow, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    String word;
    if (dictionary.isLookupWordEmpty) {
      word = history.getWord(index);
    } else {
      word = dictionary.getMatch(index);
    }

    return MouseRegion(
        cursor:
            word == '' ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
            onTap: () {
              if (word == '') return;
              showArticle(context, word, narrow);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: LimitedBox(
                maxHeight: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(dictionary.isLookupWordEmpty ? '' : word,
                            style: TextStyle(
                                // Ikv returns original keys, i.e. not lower case
                                // probably it is better to just highlight selected index rather than compare strings
                                fontWeight: word.toLowerCase() ==
                                        dictionary.selectedWord
                                    ? FontWeight.bold
                                    : FontWeight.normal))),
                    Text(dictionary.isLookupWordEmpty ? word : '·',
                        style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontWeight: word == dictionary.selectedWord
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ],
                ),
              ),
            )));
  }
}

class _SearchBar extends StatelessWidget {
  static var _controller = TextEditingController();

  final bool narrow;

  _SearchBar(this.narrow);

  @override
  Widget build(BuildContext context) {
    var dictionary = Provider.of<MasterDictionary>(context, listen: false);

    return dictionary.isPartiallyLoaded
        ? Container(
            decoration: BoxDecoration(
                color: Theme.of(context).canvasColor,
                borderRadius: BorderRadius.only(
                    topLeft: narrow ? Radius.circular(12) : Radius.zero,
                    topRight: narrow ? Radius.circular(12) : Radius.zero)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Stack(alignment: Alignment.bottomRight, children: [
              TextField(
                controller: _controller,
                autofocus: true,
                onChanged: (text) {
                  dictionary.lookupWord = text;
                },
                onSubmitted: (value) {
                  if (dictionary.matchesCount > 0) {
                    showArticle(context, dictionary.getMatch(0), narrow);
                  }
                },
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search'.i18n,
                    suffix: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(dictionary.isPartiallyLoaded
                              ? (dictionary.isLookupWordEmpty
                                  ? ''
                                  : (dictionary.matchesCount >=
                                          dictionary.maxResults
                                      ? dictionary.maxResults.toString() + '+'
                                      : dictionary.matchesCount.toString()))
                              : '0_0'),
                          if (!dictionary.isLookupWordEmpty)
                            MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                    child: Container(
                                      //color: Colors.red,
                                      height: 32,
                                      width: 36,
                                      child: Icon(
                                        Icons.backspace_rounded,
                                        size: 24,
                                      ),
                                    ),
                                    onTap: () {
                                      dictionary.lookupWord = '';
                                      _controller.clear();
                                    }))
                        ])),
              ),
              Opacity(
                  opacity: 0.2,
                  child: Text(
                      (dictionary.lookupSw.elapsedMicroseconds / 1000)
                          .toStringAsFixed(1),
                      style: Theme.of(context).textTheme.overline))
            ]))
        : SizedBox();
  }
}

Future<List<Article>> getArticlesAndUpdateHistory(
    BuildContext context, String word) async {
  var dictionary = Provider.of<MasterDictionary>(context, listen: false);
  var history = Provider.of<History>(context, listen: false);

  List<Article> articles;
  if (dictionary.isLookupWordEmpty) {
    articles = await dictionary.getArticles(word);
    if (articles.isEmpty) articles = <Article>[Article('N/A', 'N/A', 'N/A')];
    history.removeWord(word);
  } else {
    articles = await dictionary.getArticles(word);
    history.addWord(word);
  }

  dictionary.selectedWord = word;

  return articles;
}

void showArticle(BuildContext context, String word, bool useDialog) {
  if (useDialog) {
    showDialog(
        context: context,
        barrierColor: !kIsWeb ? Colors.transparent : Colors.black54,
        routeSettings: RouteSettings(name: Routes.showArticle, arguments: word),
        builder: (BuildContext context) {
          var articles = getArticlesAndUpdateHistory(context, word);

          return SimpleSimpleDialog(
              backgroundColor:
                  !kIsWeb ? Colors.transparent : Theme.of(context).cardColor,
              elevation: 0,
              insetPadding: EdgeInsets.fromLTRB(
                  0, !kIsWeb && Platform.isMacOS ? 28 : 0, 0, 0),
              children: [
                // Let animation play rather than have some frames lost due to WordArticles
                // doing heavy work composing many articles together. E.g. when having many
                // disctionaries and showing popular word junk can be see
                FutureBuilder(
                    future:
                        Future.delayed(Duration(milliseconds: 100), () => true),
                    builder: (c, s) => s.hasData
                        ? WordArticles(
                            articles: articles,
                            word: word,
                            showAnotherWord: (word) =>
                                showArticle(context, word, useDialog),
                          )
                        : SizedBox())
              ]);
        });
  } else {
    Navigator.of(context).pushNamed(Routes.showArticleWide, arguments: word);
  }
}
