import 'package:dikt/models/history.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dikt/models/dictionary.dart';
import 'package:dikt/screens/settings.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';

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
          : (dictionary.isLookupWordEmpty && history.wordsCount < 1
              ? Positioned(
                  left: 0,
                  right: 0,
                  bottom: 100.0,
                  child: Text(
                    'Type-in word below\n↓ ↓ ↓',
                    textAlign: TextAlign.center,
                  ))
              : LookupWords(
                  barHeight: _barHeight,
                  dictionary: dictionary,
                  history: history)),
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

void showArticle(
    BuildContext context, Dictionary dictionary, History history, String word) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        String article;
        if (dictionary.isLookupWordEmpty) {
          article = dictionary.getArticle(word);
          if (article == '') {
            article = "N/A";
            history.removeWord(word);
          }
        } else {
          article = dictionary.getArticle(word);
          history.addWord(word);
        }

        // return AlertDialog(
        //     title: SelectableText(word),
        //     content: SelectableText(article));

        return AlertDialog(
            title: SelectableText(word),
            content: SingleChildScrollView(
                padding: EdgeInsets.all(0),
                child: Html(
                  data: article,
                  onLinkTap: (url) {
                    //dictionary.lookupWord = url;
                    showArticle(context, dictionary, history, url);
                  },
                  style: {
                    "div": Style(
                      fontFamily: 'sans-serif-light',
                      padding: EdgeInsets.all(0),
                      //backgroundColor: Colors.yellow
                    ),
                  },
                )));
      });
}

class _SearchBar extends StatelessWidget {
  static var _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var dictionary = Provider.of<Dictionary>(context, listen: false);

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
                                                  .toString()))
                                      : '0_0'))),
                        )
                      : Text('Loading...'),
                ]))));
  }
}
