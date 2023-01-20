import 'dart:async';
import 'dart:io';

import 'package:dikt/common/helpers.dart';
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

class Lookup extends StatefulWidget {
  final bool narrow;

  const Lookup({Key? key, this.narrow = false}) : super(key: key);

  @override
  State<StatefulWidget> createState() => LookupState();
}

class LookupState extends State<Lookup> with WidgetsBindingObserver {
  bool _fullyLoaded = false;
  bool _firstBuild = true;
  bool _resumed = true;

  late TextEditingController _searchBarController;
  late FocusNode _searchBarFocusNode;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _resumed = true;
      });
    }
  }

  void _showKeyboard() {
    _searchBarFocusNode.unfocus();
    Future.delayed(const Duration(milliseconds: 100),
        () => _searchBarFocusNode.requestFocus());
  }

  @override
  void initState() {
    _searchBarController = TextEditingController();
    _searchBarFocusNode = FocusNode();

    WidgetsBinding.instance.addObserver(this);

    super.initState();
  }

  @override
  void dispose() {
    _searchBarController.dispose();
    _searchBarFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var dictionary = Provider.of<MasterDictionary>(context);
    var history = Provider.of<History>(context, listen: false);

    if (_firstBuild) {
      _firstBuild = false;
      Future.delayed(Duration.zero, () => _showKeyboard());
    }

    if (_resumed) {
      _resumed = false;
      if (_searchBarFocusNode.hasFocus) {
        Future.delayed(Duration.zero, () => _showKeyboard());
      }
    }

    if (dictionary.isFullyLoaded && !_fullyLoaded) {
      debugPrint('Dictionaries loaded, lookup view ready');
      _fullyLoaded = true;
      var v = _searchBarController.value;
      if (v.text.isNotEmpty) {
        // If there's text in search bar, trigger onChange() event to show lookup results
        _searchBarController.value = TextEditingValue.empty;
        _searchBarController.value = v;
      }
    }

    return Stack(children: [
      widget.narrow ? const DictionaryIndexingOrLoading() : const Text(''),
      Column(children: [
        !dictionary.isPartiallyLoaded
            ? const Expanded(child: Text(''))
            : ((dictionary.isLookupWordEmpty && history.wordsCount < 1) ||
                    dictionary.totalEntries == 0
                ? Expanded(
                    child: Center(
                        child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 100, 0, 0),
                            child: Text(
                              (widget.narrow
                                      ? ('${dictionary.totalEntries == 0 ? '↑↑↑\n${'Try adding dictionaries'.i18n}\n\n' : ''}${dictionary.totalEntries} ${'entries'.i18n}')
                                      : '') +
                                  (dictionary.totalEntries > 0
                                      ? '\n\n${'Type-in text below'.i18n}\n↓ ↓ ↓'
                                      : ''),
                              textAlign: TextAlign.center,
                            ))))
                : Expanded(
                    child: _WordsList(
                      dictionary: dictionary,
                      history: history,
                      narrow: widget.narrow,
                    ),
                  )),
        _SearchBar(widget.narrow, _searchBarController, _searchBarFocusNode)
      ]),
      widget.narrow ? const TopButtons() : const Text(''),
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
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            Widget x = _Entry(index, dictionary, history, narrow);
            if (index == 0) {
              x = Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 10), child: x);
            }

            return x;
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
            return const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.transparent, Colors.black],
            ).createShader(
                Rect.fromLTRB(0, rect.height - 20, rect.width, rect.height));
          },
          blendMode: BlendMode.dstIn,
          child: ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black, Colors.transparent],
                ).createShader(
                    Rect.fromLTRB(0, 0, rect.width, rect.height - 200));
              },
              blendMode: BlendMode.dstIn,
              child: sv));
    }

    return sv;
  }
}

class _Entry extends StatelessWidget {
  final int index;
  final MasterDictionary dictionary;
  final History history;
  final bool narrow;

  const _Entry(this.index, this.dictionary, this.history, this.narrow,
      {Key? key})
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
  final bool narrow;
  final TextEditingController controller;
  final FocusNode focusNode;
  //static GlobalKey _key = GlobalKey();

  const _SearchBar(this.narrow, this.controller, this.focusNode);

  @override
  Widget build(BuildContext context) {
    var dictionary = Provider.of<MasterDictionary>(context, listen: false);

    return Container(
        decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: BorderRadius.only(
                topLeft: narrow ? const Radius.circular(12) : Radius.zero,
                topRight: narrow ? const Radius.circular(12) : Radius.zero)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Stack(alignment: Alignment.bottomRight, children: [
          TextField(
            controller: controller,
            autofocus: true,
            autocorrect: false,
            focusNode: focusNode,
            onChanged: (text) {
              dictionary.lookupWord = text;
            },
            onSubmitted: (value) {
              if (dictionary.matchesCount > 0) {
                showArticle(context, dictionary.getMatch(0), narrow);
              }
            },
            style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search'.i18n,
                suffix: _SearchBarSuffix(dictionary: dictionary)),
          ),
          Opacity(
              opacity: 0.2,
              child: Text(
                  (dictionary.lookupSw.elapsedMicroseconds / 1000)
                      .toStringAsFixed(1),
                  style: Theme.of(context).textTheme.overline)),
          if (!dictionary.isLookupWordEmpty)
            _ClearInvisibleButton(
                dictionary: dictionary,
                controller: controller,
                focusNode: focusNode)
        ]));
  }
}

class _ClearInvisibleButton extends StatelessWidget {
  const _ClearInvisibleButton({
    Key? key,
    required this.dictionary,
    required this.controller,
    required this.focusNode,
  }) : super(key: key);

  final MasterDictionary dictionary;
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        child: const MouseRegion(
            cursor: SystemMouseCursors.click,
            child: SizedBox(
              height: 48,
              width: 48,
            )),
        onTap: () {
          dictionary.lookupWord = '';
          controller.clear();
          focusNode.requestFocus();
        });
  }
}

class _SearchBarSuffix extends StatelessWidget {
  const _SearchBarSuffix({
    Key? key,
    required this.dictionary,
  }) : super(key: key);

  final MasterDictionary dictionary;

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text((dictionary.isLookupWordEmpty
              ? ''
              : (dictionary.matchesCount >= dictionary.maxResults
                  ? '${dictionary.maxResults}+'
                  : dictionary.matchesCount.toString()))),
          if (!dictionary.isLookupWordEmpty)
            const SizedBox(
              height: 24,
              width: 36,
              child: Icon(
                Icons.backspace_rounded,
                size: 24,
              ),
            ),
        ]);
  }
}

Future<List<Article>> getArticles(BuildContext context, String word) async {
  var dictionary = Provider.of<MasterDictionary>(context, listen: false);

  List<Article> articles;
  if (dictionary.isLookupWordEmpty) {
    articles = await dictionary.getArticles(word);
    if (articles.isEmpty) {
      articles = <Article>[Article('N/A', 'N/A', 'N/A')];
    }
  } else {
    articles = await dictionary.getArticles(word);
  }

  return articles;
}

void showArticle(BuildContext context, String word, bool useDialog) {
  var history = Provider.of<History>(context, listen: false);
  history.addWord(word);
  var dictionary = Provider.of<MasterDictionary>(context, listen: false);
  dictionary.selectedWord = word;

  if (useDialog) {
    showDialog(
        context: context,
        barrierColor: !kIsWeb ? Colors.transparent : Colors.black54,
        routeSettings: RouteSettings(name: Routes.showArticle, arguments: word),
        builder: (BuildContext context) {
          var articles = getArticles(context, word);

          return SimpleSimpleDialog(
              backgroundColor: Theme.of(context).cardColor,
              elevation: 0,
              insetPadding: EdgeInsets.fromLTRB(
                  0, !kIsWeb && Platform.isMacOS ? 28 : 0, 0, 0),
              children: [
                KeyboardVisibilityBuilder(
                    builder: (c, iv) => iv
                        ? const SizedBox()
                        : FutureBuilder(
                            future: Future.delayed(
                                const Duration(milliseconds: 80), () => true),
                            builder: (c, s) => s.hasData
                                ? WordArticles(
                                    articles: articles,
                                    word: word,
                                    showAnotherWord: (word) =>
                                        showArticle(context, word, useDialog),
                                  )
                                : const SizedBox()))
              ]);
        });
  } else {
    Navigator.of(context).pushNamed(Routes.showArticleWide, arguments: word);
  }
}
