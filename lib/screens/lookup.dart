import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dikt/models/masterDictionary.dart';
import 'package:dikt/screens/settings.dart';
import 'package:double_back_to_close_app/double_back_to_close_app.dart';

import '../models/masterDictionary.dart';
import '../common/simpleSimpleDialog.dart'
    show SimpleSimpleDialog; //TODO: cleanup this file
import './settings.dart';
import './wordArticles.dart';
import './dictionaries.dart';
import './managerState.dart';
import '../models/dictionaryManager.dart';
import '../models/history.dart';

final _scaffoldKey = GlobalKey<ScaffoldState>();

class Lookup extends StatelessWidget {
  static const double _barHeight = 60;

  @override
  Widget build(BuildContext context) {
    var dictionary = Provider.of<MasterDictionary>(context);
    var history = Provider.of<History>(context, listen: false);
    var manager = Provider.of<DictionaryManager>(context);

    return Scaffold(
        key: _scaffoldKey,
        body: DoubleBackToCloseApp(
            snackBar: const SnackBar(
              content: Text('Tap back again to quit'),
            ),
            child: Stack(children: [
              !dictionary.isLoaded
                  ? ManagerState(manager: manager)
                  : (dictionary.isLookupWordEmpty && history.wordsCount < 1
                      ? Positioned(
                          left: 0,
                          right: 0,
                          bottom: 100.0,
                          child: Text(
                            dictionary.totalEntries.toString() +
                                ' words\n\nType-in text below\n↓ ↓ ↓',
                            textAlign: TextAlign.center,
                          ))
                      : LookupWords(
                          barHeight: _barHeight,
                          dictionary: dictionary,
                          history: history)),
              _SearchBar(),
              dictionary.isLoaded ? TopButtons() : Text('.. ..'),
            ])));
  }
}

class TopButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        minimum: const EdgeInsets.all(20),
        child: Align(
            alignment: Alignment.topRight,
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              IconButton(
                  icon: Icon(Icons.dns, size: 30),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return SimpleSimpleDialog(
                              title: Text('Dictionaries'),
                              children: [Dictionaries()]);
                        });
                  }),
              IconButton(
                icon: Icon(
                  Icons.apps,
                  size: 30,
                ),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                            title: Text('Settings'), content: Settings());
                      });
                },
              )
            ])));
  }
}

class LookupWords extends StatelessWidget {
  const LookupWords(
      {@required double barHeight,
      @required this.dictionary,
      @required this.history})
      : _barHeight = barHeight;

  final double _barHeight;
  final MasterDictionary dictionary;
  final History history;

  static const int _emptyEntries = 5; //allow to reach top items

  @override
  Widget build(BuildContext context) {
    Widget sv = CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return _Entry(index, dictionary, history);
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

  _Entry(this.index, this.dictionary, this.history, {Key key})
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
            if (word == '' || word == null) return;
            showArticle(context, dictionary, history, word);
          },
          child: LimitedBox(
            maxHeight: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(dictionary.isLookupWordEmpty ? '' : word)),
                Text(dictionary.isLookupWordEmpty ? word : '·',
                    style: TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ));
  }
}

void showArticle(BuildContext context, MasterDictionary dictionary,
    History history, String word) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        Future<List<Article>> articles;
        if (dictionary.isLookupWordEmpty) {
          articles = dictionary.getArticles(word);
          if (articles == null) {
            articles =
                Future<List<Article>>.value([Article('N/A', 'N/A', 'N/A')]);
            history.removeWord(word);
          }
        } else {
          articles = dictionary.getArticles(word);
          history.addWord(word);
        }

        return SimpleSimpleDialog(
            // title: SelectableText(word),
            //scrollable: false,
            children: [
              WordArticles(
                articles: articles,
                word: word,
                showAnotherWord: (word) =>
                    showArticle(context, dictionary, history, word),
              )
            ]);
      });
}

class _SearchBar extends StatelessWidget {
  static var _controller = TextEditingController();

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
                child: Stack(children: [
                  dictionary.isLoaded
                      ? TextField(
                          controller: _controller,
                          autofocus: true,
                          onChanged: (text) {
                            dictionary.lookupWord = text;
                          },
                          style: TextStyle(fontSize: 20.0),
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Search',
                              suffix: GestureDetector(
                                  onTap: () {
                                    dictionary.lookupWord = '';
                                    _controller.clear();
                                  },
                                  child: Text(dictionary.isLoaded
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
                      : Text('...'),
                ]))));
  }
}
