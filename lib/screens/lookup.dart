import 'package:dikt/models/history.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dikt/models/dictionary.dart';
import 'package:dikt/screens/settings.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class Lookup extends StatelessWidget {
  static const double _barHeight = 60;

  @override
  Widget build(BuildContext context) {
    var dictionary = Provider.of<Dictionary>(context);
    var history = Provider.of<History>(context, listen: false);

    return Scaffold(
        body: Stack(children: [
      !dictionary.isLoaded
          ? Center(child: Text('One moment please'))
          : LookupWords(
              barHeight: _barHeight, dictionary: dictionary, history: history),
      _SearchBar(),
      SettingsButton(),
    ]));
  }
}

class SettingsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        minimum: const EdgeInsets.all(20),
        child: Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                          title: Text('Settings'), content: Settings());
                    });
              },
            )));
  }
}

class LookupWords extends StatelessWidget {
  const LookupWords(
      {@required double barHeight,
      @required this.dictionary,
      @required this.history})
      : _barHeight = barHeight;

  final double _barHeight;
  final Dictionary dictionary;
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
  final Dictionary dictionary;
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
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  String article;
                  if (dictionary.isLookupWordEmpty) {
                    article = dictionary.getArticle(word);
                  } else {
                    article = dictionary.getArticleFromMatches(index);
                    history.addWord(word);
                  }

                  return AlertDialog(
                      title: SelectableText(word),
                      content: SelectableText(article));
                });
          },
          child: LimitedBox(
            maxHeight: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    word,
                    textAlign: dictionary.isLookupWordEmpty
                        ? TextAlign.end
                        : TextAlign.start,
                    style: TextStyle(
                        fontStyle: dictionary.isLookupWordEmpty
                            ? FontStyle.italic
                            : FontStyle.normal),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var model = Provider.of<Dictionary>(context);

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
                  model.isLoaded
                      ? TextField(
                          autofocus: true,
                          onChanged: (text) {
                            model.lookupWord = text;
                          },
                          style: TextStyle(fontSize: 20.0),
                          decoration: InputDecoration(
                            fillColor: Colors.amber,
                            border: InputBorder.none,
                            hintText: 'Search',
                          ))
                      : Text('Loading...'),
                  Positioned.fill(
                      child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(model.isLoaded
                              ? (model.matchesCount > model.maxResults
                                  ? model.maxResults.toString() + '+'
                                  : model.matchesCount.toString())
                              : '0_0'))),
                ]))));
  }
}
