import 'dart:async';
import 'dart:io';

import 'package:dikt/models/indexedDictionary.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:reorderables/reorderables.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_chooser/file_chooser.dart';

import '../../models/dictionaryManager.dart';
import '../../models/masterDictionary.dart';
import '../../common/i18n.dart';
import '../elements/managerState.dart';
import '../routes.dart';
import '../../models/onlineDictionaries.dart';

class _SwitchedToOnline {
  bool yes = false;
}

class Dictionaries extends HookWidget {
  static bool toastShown = false;
  final bool _offline;

  Dictionaries(bool offline) : _offline = offline;

  @override
  Widget build(BuildContext context) {
    if (!toastShown) {
      var fToast = FToast(context);
      Timer(
          Duration(seconds: 1),
          () => fToast.showToast(
              child: Container(
                child: Text('Tap and hold to move'.i18n),
                color: Colors.grey,
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              ),
              toastDuration: Duration(seconds: 3)));
      toastShown = true;
    }

    final switchedToOnline = useMemoized(() => _SwitchedToOnline());

    if (!_offline)
      switchedToOnline.yes = false;
    else {
      if (!switchedToOnline.yes) {
        Provider.of<OnlineDictionaryManager>(context)?.cleanUp();
        switchedToOnline.yes = true;
      }
    }

    return new WillPopScope(
        onWillPop: () async {
          var manager = Provider.of<DictionaryManager>(context, listen: false);
          if (manager.isRunning) {
            return false;
          }
          return true;
        },
        child: Stack(children: [
          Container(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
              height: 50.0,
              child: Text(
                'Dictionaries'.i18n,
                style: Theme.of(context).textTheme.headline6,
              )),
          Padding(
              padding: EdgeInsets.fromLTRB(12, 50, 12, 12),
              child: //Text('TEST')
                  _offline ? OfflineDictionaries() : OnlineDictionaries())
        ]));
  }
}

class OnlineDictionaries extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var odm = Provider.of<OnlineDictionaryManager>(context);
    const dicHeight = 50.0;

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
                                  spacing: 5,
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
          height: 40,
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

class OnlineDictionaryTile extends StatelessWidget {
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
    return Container(
        height: dicHeight,
        width: dicWidth,
        //color: Colors.yellow,
        child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Tooltip(
                        message: dictionary.repoDictionary.name,
                        waitDuration: Duration(seconds: 1),
                        child: Text(dictionary.repoDictionary.name,
                            softWrap: false,
                            maxLines: 1,
                            style: TextStyle(fontSize: 18))),
                    Text(
                        dictionary.repoDictionary.words.toString() +
                            ' words, ' +
                            (dictionary.repoDictionary.sizeBytes / 1024 / 1024)
                                .toStringAsFixed(1) +
                            'Mb',
                        softWrap: false,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.subtitle2)
                  ])),
              IconButton(
                  icon: Icon(
                      dictionary.state == OnlineDictionaryState.notDownloaded
                          ? Icons.download_sharp
                          : Icons.delete),
                  onPressed: () {})
            ]));
  }
}

class OfflineDictionaries extends StatefulWidget {
  @override
  _OfflineDictionariesState createState() => _OfflineDictionariesState();
}

class _OfflineDictionariesState extends State<OfflineDictionaries> {
  int _draggingIndex;
  bool _cancelReorder = false;

  @override
  Widget build(BuildContext context) {
    ScrollController _scrollController =
        PrimaryScrollController.of(context) ?? ScrollController();

    var manager = Provider.of<DictionaryManager>(context);

    void _onReorder(int oldIndex, int newIndex) {
      if (!_cancelReorder)
        manager.reorder(
            oldIndex, newIndex); // if reorder happens due to moving to Delete
      setState(() {
        _draggingIndex = null;
      });
    }

    void _onDragging(int index) {
      setState(() {
        _cancelReorder = false;
        _draggingIndex = index;
      });
    }

    void _onCancel(int index) {
      setState(() {
        _draggingIndex = null;
      });
    }

    void _importJson() async {
      List<PlatformFile> files = [];

      // Platform class is not implemented in Web
      if (!kIsWeb && Platform.isMacOS) {
        var x = await showOpenPanel(
          allowsMultipleSelection: true,
          canSelectDirectories: false,
          allowedFileTypes: [
            FileTypeFilterGroup(label: 'JSON', fileExtensions: ['json']),
          ],
        );

        for (var i in x.paths) {
          var f = PlatformFile(name: i);
          files.add(f);
        }
      } else {
        files = (await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowMultiple: true,
                allowedExtensions: ['json']))
            .files;
      }

      if (files != null && files.length > 0) {
        manager
            .loadFromJsonFiles(files)
            .whenComplete(() =>
                Provider.of<MasterDictionary>(context, listen: false)?.notify())
            .catchError((err) {
          showDialog(
              context: context,
              barrierColor: !kIsWeb ? Colors.transparent : Colors.black54,
              routeSettings: RouteSettings(name: '/dic_import_error'),
              builder: (context) => AlertDialog(
                    title: Text('There\'re issues...'.i18n),
                    content: IntrinsicHeight(child: ManagerState()),
                    actions: [
                      FlatButton(
                          child: Text('OK'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          }),
                    ],
                  ));
        });
      }
    }

    return Container(
        width: 400,
        child: Stack(alignment: AlignmentDirectional.bottomCenter, children: [
          DragTarget<int>(onAccept: (index) {
            _cancelReorder = true;
            showDialog(
                context: context,
                barrierColor: !kIsWeb ? Colors.transparent : Colors.black54,
                routeSettings: RouteSettings(name: '/delete_dic'),
                builder: (context) => AlertDialog(
                      content: Text('Delete_dic'
                          .i18n
                          .fill([manager.dictionariesReady[index].name])),
                      actions: [
                        FlatButton(
                          child: Text('Delete'.i18n),
                          onPressed: () {
                            manager.deleteReadyDictionary(index);
                            Provider.of<MasterDictionary>(context,
                                    listen: false)
                                ?.notify();
                            Navigator.of(context).pop();
                          },
                        ),
                        FlatButton(
                          child: Text('Cancel'.i18n),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        )
                      ],
                    ));
          }, onWillAccept: (data) {
            return true;
          }, builder: (context, List<int> candidateData, rejectedData) {
            return Container(
              width: 280,
              padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
              height: 40,
              child: Center(
                  child: _draggingIndex == null
                      ? (manager.isRunning
                          ? OutlinedButton(
                              child: Text('Break'.i18n),
                              onPressed: () {
                                manager.cancel();
                              })
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                  OutlinedButton(
                                    child: SizedBox(
                                      child: Text('+ JSON'.i18n),
                                      width: 85,
                                    ),
                                    onPressed: _importJson,
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  OutlinedButton(
                                      style: ButtonStyle(
                                          backgroundColor:
                                              MaterialStateProperty.all<Color>(
                                                  Colors.red.withAlpha(128))),
                                      child: SizedBox(
                                        child: Text('Online →'.i18n),
                                        width: 85,
                                      ),
                                      onPressed: () async {
                                        Routes.showOnlineDictionaries(context);
                                      })
                                ]))
                      : Center(child: Text('DELETE'.i18n))),
            );
          }),
          manager.isRunning
              ? Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 48),
                  child: IntrinsicHeight(child: ManagerState()))
              : Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 40),
                  child: CustomScrollView(
                    controller: _scrollController,
                    shrinkWrap: true,
                    slivers: <Widget>[
                      ReorderableSliverList(
                        delegate: ReorderableSliverChildListDelegate(manager
                            .dictionariesAll
                            .map((e) => OfflineDictionaryTile(
                                manager: manager, dictionary: e))
                            .toList()),
                        onReorder: _onReorder,
                        onDragging: _onDragging,
                        onNoReorder: _onCancel,
                      )
                    ],
                  ))
        ]));
  }
}

class OfflineDictionaryTile extends StatelessWidget {
  const OfflineDictionaryTile(
      {Key key, @required this.manager, @required this.dictionary})
      : super(key: key);

  final DictionaryManager manager;
  final IndexedDictionary dictionary;

  @override
  Widget build(BuildContext context) {
    return Opacity(
        opacity: !dictionary.isEnabled || !dictionary.isReadyToUse ? 0.5 : 1.0,
        child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          Container(
              width: 30,
              height: 50,
              child: FlatButton(
                child: Text(
                    !dictionary.isReadyToUse && dictionary.isBundled
                        ? '↻'
                        : (dictionary.isEnabled ? '↘' : '↓'),
                    style: Theme.of(context).textTheme.caption),
                padding: EdgeInsets.all(3),
                onPressed: () {
                  if (dictionary.isError) return;
                  if (!dictionary.isReadyToUse && dictionary.isBundled) {
                    manager.reindexBundledDictionaries(dictionary.boxName);
                  } else {
                    manager.switchIsEnabled(dictionary);
                    Provider.of<MasterDictionary>(context, listen: false)
                        ?.notify();
                  }
                },
              )),
          Container(
              padding: EdgeInsets.fromLTRB(6, 0, 0, 0),
              height: 55,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dictionary.name,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.caption),
                    dictionary.isError
                        ? Text('error', style: TextStyle(color: Colors.red))
                        : FutureBuilder(
                            future: dictionary
                                .openBox(), //disabled boxes are not loaded upon start
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                Timer.run(() {
                                  Provider.of<MasterDictionary>(context,
                                          listen: false)
                                      ?.notify();
                                }); // let Lookup update (e.g. no history and number of entries shown) if a new dictionary is imported
                                return Text(
                                  dictionary.box.length.toString() +
                                      ' ' +
                                      'entries'.i18n +
                                      (!kIsWeb
                                          ? ', ' +
                                              dictionary.fileSizeMb
                                                  .toStringAsFixed(1) +
                                              "MB"
                                          : ''),
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.subtitle2,
                                );
                              } else {
                                return Text('...');
                              }
                            })
                  ])),
        ]));
  }
}
