import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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

class Dictionaries extends StatelessWidget {
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
              child: _offline ? OfflineDictionaries() : OnlineDictionaries())
        ]));
  }
}

class OnlineDictionaries extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
        child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('IFPS Repo'),
        SizedBox(width: 10),
        Expanded(
            child: TextFormField(
                style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context)
                        .textTheme
                        .bodyText1
                        .color
                        .withAlpha(155)),
                initialValue:
                    'https://ipfs.io/ipfs/QmWByPsvVmTH7fMoSWFxECTWgnYJRcCZmdFzhLNhejqHzm?filename=Vanquish.exe'))
      ]),
      Container(
          padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
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
              child: AlertDialog(
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

    return Stack(children: [
      Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: DragTarget(onAccept: (index) {
            _cancelReorder = true;
            showDialog(
                context: context,
                barrierColor: !kIsWeb ? Colors.transparent : Colors.black54,
                routeSettings: RouteSettings(name: '/delete_dic'),
                child: AlertDialog(
                  content: Text('Delete_dic'
                      .i18n
                      .fill([manager.dictionariesReady[index].name])),
                  actions: [
                    FlatButton(
                      child: Text('Delete'.i18n),
                      onPressed: () {
                        manager.deleteReadyDictionary(index);
                        Provider.of<MasterDictionary>(context, listen: false)
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
          })),
      manager.isRunning
          ? IntrinsicHeight(child: ManagerState())
          : Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 40),
              child: CustomScrollView(
                controller: _scrollController,
                shrinkWrap: true,
                slivers: <Widget>[
                  ReorderableSliverList(
                    delegate: ReorderableSliverChildListDelegate(manager
                        .dictionariesAll
                        .map((e) => Opacity(
                            opacity:
                                !e.isEnabled || !e.isReadyToUse ? 0.5 : 1.0,
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                      width: 30,
                                      height: 50,
                                      child: FlatButton(
                                        child: Text(
                                          !e.isReadyToUse && e.isBundled
                                              ? '↻'
                                              : (e.isEnabled ? '↘' : '↓'),
                                          style: TextStyle(fontSize: 28),
                                        ),
                                        padding: EdgeInsets.all(3),
                                        onPressed: () {
                                          if (e.isError) return;

                                          if (!e.isReadyToUse && e.isBundled) {
                                            manager.reindexBundledDictionaries(
                                                e.boxName);
                                          } else {
                                            manager.switchIsEnabled(e);
                                            Provider.of<MasterDictionary>(
                                                    context,
                                                    listen: false)
                                                ?.notify();
                                          }
                                        },
                                      )),
                                  Expanded(
                                      child: Container(
                                          padding:
                                              EdgeInsets.fromLTRB(6, 0, 0, 0),
                                          height: 55,
                                          child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(e.name,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .caption),
                                                e.isError
                                                    ? Text('error',
                                                        style: TextStyle(
                                                            color: Colors.red))
                                                    : FutureBuilder(
                                                        future: e
                                                            .openBox(), //disabled boxes are not loaded upon start
                                                        builder: (context,
                                                            snapshot) {
                                                          if (snapshot
                                                              .hasData) {
                                                            Timer.run(() {
                                                              Provider.of<MasterDictionary>(
                                                                      context,
                                                                      listen:
                                                                          false)
                                                                  ?.notify();
                                                            }); // let Lookup update (e.g. no history and number of entries shown) if a new dictionary is imported
                                                            return Text(
                                                              e.box.length
                                                                      .toString() +
                                                                  ' ' +
                                                                  'entries'
                                                                      .i18n +
                                                                  (!kIsWeb
                                                                      ? ', ' +
                                                                          e.fileSizeMb
                                                                              .toStringAsFixed(1) +
                                                                          "MB"
                                                                      : ''),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .subtitle2,
                                                            );
                                                          } else {
                                                            return Text('...');
                                                          }
                                                        })
                                              ]))),
                                ])))
                        .toList()),
                    onReorder: _onReorder,
                    onDragging: _onDragging,
                    onNoReorder: _onCancel,
                  )
                ],
              ))
    ]);
  }
}
