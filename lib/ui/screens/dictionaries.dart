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

class Dictionaries extends StatefulWidget {
  @override
  _DictionariesState createState() => _DictionariesState();
}

class _DictionariesState extends State<Dictionaries> {
  static bool toastShown = false;
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

    if (!toastShown) {
      var fToast = FToast();
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
          if (manager.isRunning) {
            //manager.cancel(); //while undexing only Break button can stop the process
            return false;
          }
          return true;
        },
        child: Stack(children: [
          Positioned(
              bottom: 0.0,
              left: 0.0,
              right: 0.0,
              child: DragTarget(onAccept: (index) {
                _cancelReorder = true;
                showDialog(
                    context: context,
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
                  //color: Theme.of(context).cardColor,
                  padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
                  height: 60,
                  child: Center(
                      child: _draggingIndex == null
                          ? (manager.isRunning
                              ? OutlineButton(
                                  child: Text('Break'.i18n),
                                  onPressed: () {
                                    manager.cancel();
                                  })
                              : OutlineButton(
                                  child: Text('+ Import JSON'.i18n),
                                  onPressed: () async {
                                    List<File> files = [];

                                    // Platform class is not implemented in Web
                                    if (!kIsWeb && Platform.isMacOS) {
                                      var x = await showOpenPanel(
                                        allowsMultipleSelection: true,
                                        canSelectDirectories: false,
                                        allowedFileTypes: [
                                          FileTypeFilterGroup(
                                              label: 'JSON',
                                              fileExtensions: ['json']),
                                        ],
                                      );

                                      for (var i in x.paths) {
                                        var f = File(i);
                                        files.add(f);
                                      }
                                    } else {
                                      files = await FilePicker.getMultiFile(
                                          type: FileType.custom,
                                          allowedExtensions: ['json']);
                                    }

                                    if (files != null && files.length > 0) {
                                      manager
                                          .loadFromJsonFiles(files)
                                          .whenComplete(() =>
                                              Provider.of<MasterDictionary>(
                                                      context,
                                                      listen: false)
                                                  ?.notify())
                                          .catchError((err) {
                                        showDialog(
                                            context: context,
                                            routeSettings: RouteSettings(
                                                name: '/dic_import_error'),
                                            child: AlertDialog(
                                              title: Text(
                                                  'There\'re issues...'.i18n),
                                              content: IntrinsicHeight(
                                                  child: ManagerState()),
                                              actions: [
                                                FlatButton(
                                                    child: Text('OK'),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    }),
                                              ],
                                            ));
                                      });
                                    }
                                  },
                                ))
                          : Text('DELETE'.i18n)),
                );
              })),
          Padding(
              padding: EdgeInsets.fromLTRB(12, 50, 12, 60),
              child: manager.isRunning
                  ? IntrinsicHeight(child: ManagerState())
                  : CustomScrollView(
                      controller: _scrollController,
                      shrinkWrap: true,
                      slivers: <Widget>[
                        ReorderableSliverList(
                          delegate: ReorderableSliverChildListDelegate(
                              manager.dictionariesReady
                                  .map((e) => Opacity(
                                      opacity: e.isEnabled ? 1 : 0.5,
                                      child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Container(
                                                width: 30,
                                                height: 50,
                                                child: FlatButton(
                                                  child: Text(
                                                    (e.isEnabled ? '↘' : '↓'),
                                                    style:
                                                        TextStyle(fontSize: 28),
                                                  ),
                                                  padding: EdgeInsets.all(3),
                                                  onPressed: () {
                                                    if (e.isError) return;
                                                    manager.switchIsEnabled(e);
                                                    Provider.of<MasterDictionary>(
                                                            context,
                                                            listen: false)
                                                        ?.notify();
                                                  },
                                                )),
                                            Expanded(
                                                child: Container(
                                                    padding:
                                                        EdgeInsets.fromLTRB(
                                                            6, 0, 0, 0),
                                                    height: 55,
                                                    child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(e.name,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .caption),
                                                          e.isError
                                                              ? Text('error',
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .red))
                                                              : FutureBuilder(
                                                                  future: e
                                                                      .openBox(), //disabled boxes are not loaded upon start
                                                                  builder: (context,
                                                                      snapshot) {
                                                                    if (snapshot
                                                                        .hasData) {
                                                                      Timer.run(
                                                                          () {
                                                                        Provider.of<MasterDictionary>(context,
                                                                                listen: false)
                                                                            ?.notify();
                                                                      }); // let Lookup update (e.g. no history and number of entries shown) if a new dictionary is imported
                                                                      return Text(
                                                                        e.box.length.toString() +
                                                                            ' ' +
                                                                            'entries'
                                                                                .i18n +
                                                                            (!kIsWeb
                                                                                ? ', ' + e.fileSizeMb.toStringAsFixed(1) + "MB"
                                                                                : ''),
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        style: Theme.of(context)
                                                                            .textTheme
                                                                            .subtitle2,
                                                                      );
                                                                    } else {
                                                                      return Text(
                                                                          '...');
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
                    )),
          Container(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
              height: 50.0,
              child: Text(
                'Dictionaries'.i18n,
                style: Theme.of(context).textTheme.headline6,
              )),
        ]));
  }
}
