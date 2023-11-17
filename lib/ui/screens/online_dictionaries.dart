import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:superellipse_shape/superellipse_shape.dart';

import '../routes.dart';
import '../themes.dart';
import '../../common/i18n.dart';
import '../../models/online_dictionaries.dart';
import '../elements/delete_confirmation.dart';

class OnlineDictionaries extends StatelessWidget {
  const OnlineDictionaries({super.key});

  @override
  Widget build(BuildContext context) {
    var odm = Provider.of<OnlineDictionaryManager>(context);
    const dicHeight = 44.0;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('IFPS Repo'),
        const SizedBox(width: 10),
        Expanded(
            child: TextFormField(
                onChanged: (value) {
                  odm.repoUrl = value;
                },
                style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .color!
                        .withAlpha(155)),
                initialValue: odm.repoUrl)),
      ]),
      odm.loading
          ? const Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 6),
              child: LinearProgressIndicator(
                minHeight: 4,
              ))
          : const SizedBox(
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
                    ? Text(odm.repoError!)
                    : (odm.dictionaries.isEmpty
                        ? const Text('No dictonaries in the repository')
                        : Wrap(
                            clipBehavior: Clip.hardEdge,
                            spacing: 5,
                            runSpacing: 5,
                            children: odm.dictionaries
                                .map((e) =>
                                    OnlineDictionaryTile(e, dicHeight, 300))
                                .toList(),
                          )))
              ]))),
          !odm.loading ? const SizedBox() : const Text('Loading...'),
        ],
      )),
      Container(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
          height: 50,
          child: Align(
              alignment: Alignment.center,
              child: OutlinedButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          Colors.red.withAlpha(128))),
                  child: SizedBox(
                    width: 85,
                    child: Text('← Offline'.i18n),
                  ),
                  onPressed: () async {
                    Routes.showOfflineDictionaries();
                  })))
    ]);
  }
}

class OnlineDictionaryTile extends HookWidget {
  const OnlineDictionaryTile(this.dictionary, this.dicHeight, this.dicWidth,
      {super.key});

  final double dicHeight;
  final double dicWidth;
  final OnlineDictionary dictionary;

  @override
  Widget build(BuildContext context) {
    var data = useListenable(dictionary);

    Widget icon;
    var style = const TextStyle(fontSize: 22);
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
        icon = const Text('×',
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

    return SizedBox(
        height: dicHeight,
        width: dicWidth,
        //color: Colors.yellow,
        child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
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
                            color: Theme.of(context).colorScheme.secondary)
                        : LinearProgressIndicator(minHeight: dicHeight))
                    : const SizedBox(),
                TextButton(
                    onPressed: onPressed as void Function()?,
                    child: SizedBox(
                      height: dicHeight,
                      child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Center(child: icon)),
                    ))
              ])),
          Expanded(
              child: Stack(children: [
            Container(
                padding: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                    border: Border(
                        bottom: horizontalBorder, top: horizontalBorder)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Tooltip(
                          message: data.repoDictionary.name,
                          waitDuration: const Duration(seconds: 1),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                data.nameHighlighted != ''
                                    ? Material(
                                        color: ownTheme(context).textBaloon,
                                        shape: SuperellipseShape(
                                          borderRadius:
                                              BorderRadius.circular(28),
                                        ),
                                        child: Padding(
                                            padding: const EdgeInsets.only(
                                                left: 4, right: 4),
                                            child: Text(data.nameHighlighted,
                                                style: const TextStyle(
                                                    fontSize: 16))))
                                    : const SizedBox(),
                                // Clip large text
                                Flexible(
                                    child: Padding(
                                        padding: const EdgeInsets.only(left: 3),
                                        child: Text(data.nameNotHighlighted,
                                            softWrap: false,
                                            maxLines: 1,
                                            overflow: TextOverflow.clip,
                                            style:
                                                const TextStyle(fontSize: 16))))
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
                                  : ('${dictionary.repoDictionary.words} words, ${(dictionary.repoDictionary.sizeBytes / 1024 / 1024).toStringAsFixed(1)}Mb'),
                          softWrap: false,
                          maxLines: 1,
                          style: Theme.of(context).textTheme.titleSmall)
                    ])),
            data.state != OnlineDictionaryState.error
                ? const SizedBox()
                : Container(
                    color: ownTheme(context).errorShade,
                    child: Center(
                        child: Text(
                            '${data.error!} - ${data.repoDictionary.name}',
                            maxLines: 2,
                            overflow: TextOverflow.clip,
                            style: Theme.of(context).textTheme.labelSmall)))
          ])),
        ]));
  }
}
