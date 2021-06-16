import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../models/masterDictionary.dart';
import '../../common/simpleSimpleDialog.dart';
import '../../common/i18n.dart';

import '../elements/wordArticles.dart';
import '../elements/topButtons.dart';
import '../elements/loadingProgress.dart';
import '../../models/history.dart';
import '../routes.dart';

class Lookup extends StatelessWidget {
  static const double _barHeight = 60;

  final bool narrow;

  Lookup(this.narrow);

  @override
  Widget build(BuildContext context) {
    var dictionary = Provider.of<MasterDictionary>(context);
    var history = Provider.of<History>(context, listen: false);

    return Stack(children: [
      narrow ? DictionaryIndexingOrLoading() : Text(''),
      !dictionary.isPartiallyLoaded
          ? Text('')
          : ((dictionary.isLookupWordEmpty && history.wordsCount < 1) ||
                  dictionary.totalEntries == 0
              ? Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, _barHeight + 20),
                  child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Text(
                        (narrow
                                ? ((dictionary.totalEntries == 0
                                        ? '↑↑↑\n' +
                                            'Try adding dictionaries'.i18n +
                                            '\n\n'
                                        : '') +
                                    dictionary.totalEntries.toString() +
                                    ' ' +
                                    'entries'.i18n)
                                : '') +
                            (dictionary.totalEntries > 0
                                ? '\n\n' + 'Type-in text below'.i18n + '\n↓ ↓ ↓'
                                : ''),
                        textAlign: TextAlign.center,
                      )))
              : LookupWords(
                  barHeight: _barHeight,
                  dictionary: dictionary,
                  history: history,
                  narrow: narrow,
                )),
      _SearchBar(narrow),
      narrow ? TopButtons() : Text(''),
    ]);
  }
}

class LookupWords extends StatelessWidget {
  const LookupWords(
      {required double barHeight,
      required this.dictionary,
      required this.history,
      required this.narrow})
      : _barHeight = barHeight;

  final double _barHeight;
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

    return Padding(
        padding: EdgeInsets.only(
            left: 0.0, top: 0.0, right: 0.0, bottom: _barHeight),
        child: sv);
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

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GestureDetector(
          onTap: () {
            if (word == '') return;
            showArticle(context, word, narrow);
          },
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
                            fontWeight:
                                word.toLowerCase() == dictionary.selectedWord
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
        ));
  }
}

class _SearchBar extends StatelessWidget {
  static var _controller = TextEditingController();

  final bool narrow;

  _SearchBar(this.narrow);

  @override
  Widget build(BuildContext context) {
    var dictionary = Provider.of<MasterDictionary>(context, listen: false);

    return Positioned(
        bottom: 0.0,
        left: 0.0,
        right: 0.0,
        height: Lookup._barHeight,
        child: Container(
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Stack(alignment: Alignment.bottomRight, children: [
                  dictionary.isPartiallyLoaded
                      ? TextField(
                          controller: _controller,
                          autofocus: true,
                          onChanged: (text) {
                            dictionary.lookupWord = text;
                          },
                          onSubmitted: (value) {
                            if (dictionary.matchesCount > 0) {
                              showArticle(
                                  context, dictionary.getMatch(0), narrow);
                            }
                          },
                          style: TextStyle(fontSize: 20.0),
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Search'.i18n,
                              suffix: GestureDetector(
                                  onTap: () {
                                    dictionary.lookupWord = '';
                                    _controller.clear();
                                  },
                                  child: Text(dictionary.isPartiallyLoaded
                                      ? (dictionary.isLookupWordEmpty
                                          ? ''
                                          : (dictionary.matchesCount >
                                                      dictionary.maxResults
                                                  ? dictionary.maxResults
                                                          .toString() +
                                                      '+'
                                                  : dictionary.matchesCount
                                                      .toString()) +
                                              '  ╳')
                                      : '0_0'))),
                        )
                      : Text(''),
                  Opacity(
                      opacity: 0.2,
                      child: Text(
                          (dictionary.lookupSw.elapsedMicroseconds / 1000)
                              .toStringAsFixed(1),
                          style: Theme.of(context).textTheme.overline))
                ]))));
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
                WordArticles(
                  articles: articles,
                  word: word,
                  showAnotherWord: (word) =>
                      showArticle(context, word, useDialog),
                )
              ]);
        });
  } else {
    Navigator.of(context).pushNamed(Routes.showArticleWide, arguments: word);
  }
}
