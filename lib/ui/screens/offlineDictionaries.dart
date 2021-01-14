import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:ikvpack/ikvpack.dart';
import 'package:reorderables/reorderables.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_chooser/file_chooser.dart';

import '../../models/dictionaryManager.dart';
import '../../models/masterDictionary.dart';
import '../../common/i18n.dart';
import '../elements/managerState.dart';
import '../routes.dart';
import '../../models/indexedDictionary.dart';
import '../../ui/elements/deleteConfirmation.dart';

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

    void _importJsonOrDikt() async {
      List<PlatformFile> files = [];

      // Platform class is not implemented in Web
      if (!kIsWeb && Platform.isMacOS) {
        var x = await showOpenPanel(
          allowsMultipleSelection: true,
          canSelectDirectories: false,
          allowedFileTypes: [
            FileTypeFilterGroup(
                label: 'JSON, DIKT', fileExtensions: ['json', 'dikt']),
          ],
        );

        for (var i in x.paths) {
          var f = PlatformFile(name: i);
          files.add(f);
        }
      } else {
        files = (await FilePicker.platform
                .pickFiles(type: FileType.any, allowMultiple: true
                    //Android greys out .dikt, some issue with MIME
                    // type: FileType.custom,
                    // allowMultiple: true,
                    // allowedExtensions: ['json', 'dikt'])
                    ))
            ?.files;
      }

      if (files != null && files.length > 0) {
        manager
            .loadFromJsonOrDiktFiles(files)
            .whenComplete(() =>
                Provider.of<MasterDictionary>(context, listen: false)?.notify())
            .catchError((err) {
          showDialog(
              context: context,
              barrierColor: !kIsWeb ? Colors.transparent : Colors.black54,
              routeSettings: RouteSettings(name: '/dic_import_error'),
              builder: (context) => AlertDialog(
                    title: Text('There\'re issues...'.i18n),
                    content: SingleChildScrollView(child: ManagerState(true)),
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
        child: Stack(alignment: AlignmentDirectional.bottomCenter, children: [
      DragTarget<int>(onAccept: (index) {
        _cancelReorder = true;
        confirmAndDelete(context, manager.dictionariesReady[index].name, () {
          manager.deleteReadyDictionary(index);
          Provider.of<MasterDictionary>(context, listen: false)?.notify();
        });
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
                                onPressed: _importJsonOrDikt,
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
              child: SingleChildScrollView(child: ManagerState()))
          : Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 40),
              child: CustomScrollView(
                controller: _scrollController,
                shrinkWrap: true,
                slivers: <Widget>[
                  ReorderableSliverList(
                    delegate: ReorderableSliverChildListDelegate(manager
                        //.dictionariesAll
                        .dictionariesReady
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
                    manager.reindexBundledDictionaries(dictionary.ikvPath);
                  } else {
                    manager.switchIsEnabled(dictionary);
                    Provider.of<MasterDictionary>(context, listen: false)
                        ?.notify();
                  }
                },
              )),
          Flexible(
              child: Container(
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
                                    .openIkv(), //disabled boxes are not loaded upon start
                                builder: (context, snapshot) {
                                  if (snapshot.hasData &&
                                      snapshot.data != null) {
                                    Timer.run(() {
                                      Provider.of<MasterDictionary>(context,
                                              listen: false)
                                          ?.notify();
                                    }); // let Lookup update (e.g. no history and number of entries shown) if a new dictionary is imported
                                    var ikv = snapshot.data as IkvPack;
                                    return Text(
                                      ikv.length.toString() +
                                          ' ' +
                                          'entries'.i18n +
                                          (!kIsWeb
                                              ? ', ' +
                                                  (ikv.sizeBytes / 1024 / 1024)
                                                      .toStringAsFixed(1) +
                                                  "MB"
                                              : ''),
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          Theme.of(context).textTheme.subtitle2,
                                    );
                                  } else {
                                    return Text('...');
                                  }
                                })
                      ]))),
        ]));
  }
}
