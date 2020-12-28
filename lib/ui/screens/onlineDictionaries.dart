import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:superellipse_shape/superellipse_shape.dart';

import '../routes.dart';
import '../themes.dart';
import '../../common/i18n.dart';
import '../../models/onlineDictionaries.dart';
import '../../ui/elements/deleteConfirmation.dart';

class OnlineDictionaries extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var odm = Provider.of<OnlineDictionaryManager>(context);
    const dicHeight = 44.0;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('IFPS Repo'),
        SizedBox(width: 10),
        Expanded(
            child: TextFormField(
                onChanged: (value) {
                  odm.repoUrl = value;
                },
                style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context)
                        .textTheme
                        .bodyText2
                        .color
                        .withAlpha(155)),
                initialValue: odm.repoUrl)),
      ]),
      odm.loading
          ? Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 6),
              child: LinearProgressIndicator(
                minHeight: 4,
              ))
          : SizedBox(
              height: 10,
            ),
      Flexible(
          child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
              opacity: odm.loading ? 0.1 : 1,
              child: SingleChildScrollView(
                  child: Column(children: [
                (odm.repoError != null
                    ? Text(odm.repoError)
                    : (odm.dictionaries == null || odm.dictionaries.length == 0
                        ? Text('No dictonaries in the repository')
                        : LayoutBuilder(
                            builder: (context, constraints) => Wrap(
                                  clipBehavior: Clip.hardEdge,
                                  spacing: 5,
                                  runSpacing: 5,
                                  children: odm.dictionaries
                                      .map((e) => OnlineDictionaryTile(
                                          e,
                                          dicHeight,
                                          constraints.maxWidth < 440
                                              ? 440
                                              : constraints.maxWidth / 2 - 5))
                                      .toList(),
                                ))))
              ]))),
          !odm.loading ? SizedBox() : Text('Loading...'),
        ],
      )),
      Container(
          padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
          height: 50,
          child: Align(
              alignment: Alignment.center,
              child: OutlinedButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          Colors.red.withAlpha(128))),
                  child: SizedBox(
                    child: Text('← Offline'.i18n),
                    width: 85,
                  ),
                  onPressed: () async {
                    Routes.showOfflineDictionaries(context);
                  })))
    ]);
  }
}

class OnlineDictionaryTile extends HookWidget {
  const OnlineDictionaryTile(this.dictionary, this.dicHeight, this.dicWidth,
      {Key key = null})
      : super(
          key: key,
        );

  final double dicHeight;
  final double dicWidth;
  final OnlineDictionary dictionary;

  @override
  Widget build(BuildContext context) {
    var data = useListenable(dictionary);

    Widget icon;
    var style = TextStyle(fontSize: 22);
    Function onPressed;

    switch (data.state) {
      case OnlineDictionaryState.indexing:
      case OnlineDictionaryState.downloading:
        icon = Text('■', style: style); //Icons.cancel;
        onPressed = () {
          data.cancelDownload();
        };
        break;
      case OnlineDictionaryState.downloaded:
        icon = Text('×',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold)); //Icons.delete;
        onPressed = () {
          confirmAndDelete(context, data.repoDictionary.name, () {
            data.deleteOffline();
          });
        };
        break;
      case OnlineDictionaryState.error:
        onPressed = () {
          data.download();
        };
        icon = Text('↻', style: style);
        break;
      default:
        onPressed = () {
          data.download();
        };
        icon = Text('+', style: style); //Icons.download_sharp;
    }

    var horizontalBorder = BorderSide(
        color: Colors.grey
            .withAlpha(data.state == OnlineDictionaryState.downloaded ? 40 : 0),
        width: 1);

    return Container(
        height: dicHeight,
        width: dicWidth,
        //color: Colors.yellow,
        child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                  width: 30,
                  height: dicHeight,
                  decoration: BoxDecoration(
                      color: data.state == OnlineDictionaryState.error
                          ? ownTheme(context).errorShade
                          : Colors.grey.withAlpha(
                              data.state == OnlineDictionaryState.downloaded
                                  ? 0
                                  : 0),
                      border: Border(
                          bottom: horizontalBorder,
                          top: horizontalBorder,
                          right: BorderSide(
                              color: Colors.grey.withAlpha(
                                  data.state == OnlineDictionaryState.downloaded
                                      ? 40
                                      : 0),
                              width: 1))),
                  child: Stack(children: [
                    data.state == OnlineDictionaryState.downloading ||
                            data.state == OnlineDictionaryState.indexing
                        ? (data.progressPercent > -1
                            ? Container(
                                width: 30 * (data.progressPercent / 100),
                                height: 40,
                                color: Theme.of(context).accentColor)
                            : LinearProgressIndicator(minHeight: dicHeight))
                        : SizedBox(),
                    FlatButton(
                        height: dicHeight,
                        padding: EdgeInsets.zero,
                        mouseCursor: SystemMouseCursors.click,
                        child: icon,
                        onPressed: onPressed)
                  ])),
              Expanded(
                  child: Stack(children: [
                Container(
                    padding: EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: horizontalBorder, top: horizontalBorder)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Tooltip(
                              message: data.repoDictionary.name,
                              waitDuration: Duration(seconds: 1),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    data.nameHighlighted != ''
                                        ? Material(
                                            color: ownTheme(context).textBaloon,
                                            shape: SuperellipseShape(
                                              borderRadius:
                                                  BorderRadius.circular(28),
                                            ),
                                            child: Padding(
                                                padding: EdgeInsets.only(
                                                    left: 4, right: 4),
                                                child: Text(
                                                    data.nameHighlighted,
                                                    style: TextStyle(
                                                        fontSize: 16))))
                                        : SizedBox(),
                                    // Clip large text
                                    Flexible(
                                        child: Padding(
                                            padding: EdgeInsets.only(left: 3),
                                            child: Text(data.nameNotHighlighted,
                                                softWrap: false,
                                                maxLines: 1,
                                                overflow: TextOverflow.clip,
                                                style:
                                                    TextStyle(fontSize: 16))))
                                  ])),
                          Text(
                              data.state == OnlineDictionaryState.downloading
                                  ? 'Downloading...'.i18n +
                                      (data.progressPercent > -1
                                          ? ' ${data.progressPercent}%'
                                          : '')
                                  : data.state == OnlineDictionaryState.indexing
                                      ? 'Indexing...'.i18n +
                                          (data.progressPercent > -1
                                              ? ' ${data.progressPercent}%'
                                              : '')
                                      : (dictionary.repoDictionary.words
                                              .toString() +
                                          ' words, ' +
                                          (dictionary.repoDictionary.sizeBytes /
                                                  1024 /
                                                  1024)
                                              .toStringAsFixed(1) +
                                          'Mb'),
                              softWrap: false,
                              maxLines: 1,
                              style: Theme.of(context).textTheme.subtitle2)
                        ])),
                data.state != OnlineDictionaryState.error
                    ? SizedBox()
                    : Container(
                        color: ownTheme(context).errorShade,
                        child: Center(
                            child: Text(
                                data.error + ' - ' + data.repoDictionary.name,
                                maxLines: 2,
                                overflow: TextOverflow.clip,
                                style: Theme.of(context).textTheme.overline)))
              ])),
            ]));
  }
}
