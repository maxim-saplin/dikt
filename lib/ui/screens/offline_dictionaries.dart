import 'dart:async';
import 'dart:io';

import 'package:dikt/common/isolate_pool.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ikvpack/ikvpack.dart';
import 'package:reorderables/reorderables.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';

import '../../models/dictionary_manager.dart';
import '../../models/master_dictionary.dart';
import '../../common/i18n.dart';
import '../elements/manager_state.dart';
import '../routes.dart';
import '../../models/indexed_dictionary.dart';
import '../elements/delete_confirmation.dart';

class OfflineDictionaries extends StatefulWidget {
  const OfflineDictionaries({Key? key}) : super(key: key);

  @override
  OfflineDictionariesState createState() => OfflineDictionariesState();
}

class OfflineDictionariesState extends State<OfflineDictionaries> {
  int? _draggingIndex;
  bool _cancelReorder = false;

  @override
  Widget build(BuildContext context) {
    ScrollController scrollController = PrimaryScrollController.of(context);

    var manager = Provider.of<DictionaryManager>(context);
    var dictionaries = manager.dictionariesAll;

    void onReorder(int oldIndex, int newIndex) {
      if (!_cancelReorder) {
        manager.reorder(oldIndex, newIndex);
      } // if reorder happens due to moving to Delete
      setState(() {
        _draggingIndex = null;
      });
    }

    void onDragging(int index) {
      setState(() {
        _cancelReorder = false;
        _draggingIndex = index;
      });
    }

    void onCancel(int index) {
      setState(() {
        _draggingIndex = null;
      });
    }

    void importJsonOrDikt() async {
      List<PlatformFile>? files = [];

      manager.gettingFileList = true;

      // Platform class is not implemented in Web
      if (!kIsWeb &&
          (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
        const XTypeGroup jsonOrDiktTypeGroup = XTypeGroup(
          // ODO - return back to normal
          label: 'JSON or DIKT/MDIKT',
          extensions: ['json', 'dikt', 'mdikt'],
        );

        var x =
            await FileSelectorPlatform.instance.openFiles(acceptedTypeGroups: [
          jsonOrDiktTypeGroup,
        ]
                // allowsMultipleSelection: true,
                // canSelectDirectories: false,
                // allowedFileTypes: [
                //   FileTypeFilterGroup(
                //       label: 'JSON, DIKT', fileExtensions: ['json', 'dikt']),
                // ],
                );

        for (var i in x) {
          var f = PlatformFile(name: i.path, size: -1);
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

      manager.gettingFileList = false;

      if (files != null && files.isNotEmpty) {
        manager
            .indexAndLoadJsonOrDiktFiles(files)
            .whenComplete(() =>
                Provider.of<MasterDictionary>(context, listen: false).notify())
            .catchError((err) {
          showDialog(
              context: context,
              barrierColor: !kIsWeb ? Colors.transparent : Colors.black54,
              routeSettings: const RouteSettings(name: '/dic_import_error'),
              builder: (context) => AlertDialog(
                    title: Text('There\'re issues...'.i18n),
                    content: const SingleChildScrollView(
                        child: ManagerState(onlyErrors: true)),
                    actions: [
                      TextButton(
                          child: const Text('OK'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          }),
                    ],
                  ));
        });
      }
    }

    return SizedBox(
        width: 450,
        child: Stack(alignment: AlignmentDirectional.bottomCenter, children: [
          DragTarget<int>(onAccept: (index) {
            _cancelReorder = true;
            confirmAndDelete(context, dictionaries[index].name, () {
              manager.deleteDictionary(dictionaries[index].ikvPath);
              Provider.of<MasterDictionary>(context, listen: false).notify();
            });
          }, onWillAccept: (data) {
            return true;
          }, builder: (context, List<int?> candidateData, rejectedData) {
            return Container(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              height: 40,
              color: candidateData.isNotEmpty
                  ? Colors.red.withAlpha(128)
                  : Colors.transparent,
              child: _draggingIndex == null
                  ? (manager.isRunning
                      ? OutlinedButton(
                          child: Text('Break'.i18n),
                          onPressed: () {
                            manager.cancel();
                          })
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              OutlinedButton(
                                onPressed: importJsonOrDikt,
                                child: SizedBox(
                                  width: 85,
                                  height: 30,
                                  child: Center(child: Text('+ FILE'.i18n)),
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              kReleaseMode
                                  ? const SizedBox()
                                  : OutlinedButton(
                                      style: ButtonStyle(
                                          backgroundColor:
                                              MaterialStateProperty.all<Color>(
                                                  Colors.red.withAlpha(128))),
                                      child: SizedBox(
                                        width: 85,
                                        height: 30,
                                        child: Center(
                                            child: Text('Online →'.i18n)),
                                      ),
                                      onPressed: () async {
                                        Routes.showOnlineDictionaries();
                                      })
                            ]))
                  : Center(child: Text('DELETE'.i18n)),
            );
          }),
          manager.isRunning
              ? const Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 48),
                  child: SingleChildScrollView(child: ManagerState()),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 40),
                  child: CustomScrollView(
                    controller: scrollController,
                    shrinkWrap: true,
                    slivers: <Widget>[
                      ReorderableSliverList(
                        delegate: ReorderableSliverChildListDelegate(
                            dictionaries
                                //.dictionariesReady
                                .map((e) => OfflineDictionaryTile(
                                    manager: manager, dictionary: e))
                                .toList()),
                        onReorder: onReorder,
                        onDragging: onDragging,
                        onNoReorder: onCancel,
                      )
                    ],
                  )),
          manager.gettingFileList
              ? Positioned.fill(
                  child: ColoredBox(
                      color: Theme.of(context).cardColor.withAlpha(196),
                      child: Center(child: Text('Loading...'.i18n))))
              : const SizedBox()
        ]));
  }
}

enum _TileState { notLoaded, loading, loaded }

class _LoadAndEnabledButton extends HookWidget {
  final IndexedDictionary dictionary;
  final DictionaryManager manager;

  const _LoadAndEnabledButton(this.dictionary, this.manager);

  void _swithcEnabled(BuildContext context) {
    manager.switchIsEnabled(dictionary);
    Provider.of<MasterDictionary>(context, listen: false).notify();
  }

  @override
  Widget build(BuildContext context) {
    var state = useState<_TileState>(
        dictionary.isLoaded ? _TileState.loaded : _TileState.notLoaded);

    if (state.value == _TileState.loaded) {
      return TextButton(
          child: Padding(
              padding: const EdgeInsets.all(3),
              child: Text('↓', style: Theme.of(context).textTheme.bodySmall)),
          onPressed: () {
            if (dictionary.isError) return;
            _swithcEnabled(context);
          });
    } else if (state.value == _TileState.loading) {
      return Center(
          child: SizedBox(
              width: 22,
              height: 22,
              child: FadeTransition(
                  opacity: useAnimationController(
                      duration: const Duration(seconds: 2))
                    ..forward(from: 0.0),
                  child: const CircularProgressIndicator(strokeWidth: 5))));
    }

    return TextButton(
        child: Padding(
            padding: const EdgeInsets.all(3),
            child: Text('↓', style: Theme.of(context).textTheme.bodySmall)),
        onPressed: () {
          dictionary.openIkvs(pool).then((value) {
            _swithcEnabled(context);
          });
          state.value = _TileState.loading;
        });
  }
}

class OfflineDictionaryTile extends StatelessWidget {
  const OfflineDictionaryTile(
      {Key? key, required this.manager, required this.dictionary})
      : super(key: key);

  final DictionaryManager manager;
  final IndexedDictionary dictionary;

  @override
  Widget build(BuildContext context) {
    var info = dictionary.getInfo();
    return Opacity(
        opacity: !dictionary.isEnabled || !dictionary.isReadyToUse ? 0.5 : 1.0,
        child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                  width: 30,
                  height: 50,
                  child: !dictionary.isReadyToUse && dictionary.isBundled
                      ? TextButton(
                          child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Text('↻',
                                  style:
                                      Theme.of(context).textTheme.bodySmall)),
                          onPressed: () {
                            //if (dictionary.isError) return;
                            manager
                                .reindexBundledDictionaries(dictionary.ikvPath);
                          })
                      : (dictionary.isEnabled
                          ? TextButton(
                              child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: Text('↘',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall)),
                              onPressed: () {
                                if (dictionary.isError) return;
                                manager.switchIsEnabled(dictionary);
                                Provider.of<MasterDictionary>(context,
                                        listen: false)
                                    .notify();
                              })
                          : _LoadAndEnabledButton(dictionary, manager))),
              Flexible(
                  child: Container(
                      padding: const EdgeInsets.fromLTRB(6, 0, 0, 0),
                      height: 55,
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dictionary.name,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall),
                            dictionary.isError
                                ? const Text('error',
                                    style: TextStyle(color: Colors.red))
                                : FutureBuilder(
                                    future:
                                        info, //disabled boxes are not loaded upon start
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData &&
                                          snapshot.data != null &&
                                          snapshot.error == null) {
                                        Timer.run(() {
                                          Provider.of<MasterDictionary>(context,
                                                  listen: false)
                                              .notify();
                                        }); // let Lookup update (e.g. no history and number of entries shown) if a new dictionary is imported
                                        var info = snapshot.data as IkvInfo;
                                        return Text(
                                          '${info.count} ${'entries'.i18n}${!kIsWeb ? ', ${(info.sizeBytes / 1024 / 1024).toStringAsFixed(1)}MB' : ''}',
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall,
                                        );
                                      } else {
                                        return const Text('...');
                                      }
                                    })
                          ]))),
            ]));
  }
}
