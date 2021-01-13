import 'package:dikt/models/masterDictionary.dart';
import 'package:dikt/ui/elements/managerState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import '../../models/dictionaryManager.dart';
import '../../common/i18n.dart';

class DictionaryIndexingOrLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!fadeShown) {
      var manager = Provider.of<DictionaryManager>(context);
      switch (manager.currentOperation) {
        // case ManagerCurrentOperation.loading:
        //   return DictionaryLoading();
        case ManagerCurrentOperation.indexing:
          return Padding(padding: EdgeInsets.all(12), child: ManagerState());
        default:
          return DictionaryLoading();
      }
    }

    return SizedBox();
  }
}

class DictionaryIndexing extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!fadeShown) {
      var manager = Provider.of<DictionaryManager>(context);
      return manager.currentOperation == ManagerCurrentOperation.indexing
          ? Padding(padding: EdgeInsets.all(12), child: ManagerState())
          : Text('');
    }

    return SizedBox();
  }
}

class DictionaryLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.topCenter,
        child: Padding(
            padding: EdgeInsets.fromLTRB(0, 120, 0, 0),
            child: DictionaryLoadingNoAlign()));
  }
}

bool fadeShown = false;

class DictionaryLoadingNoAlign extends HookWidget {
  @override
  Widget build(BuildContext context) {
    var manager = Provider.of<DictionaryManager>(context);

    var count = manager.dictionariesBeingProcessed.fold(
        0,
        (previousValue, element) =>
            previousValue +
            (element.state == DictionaryBeingProcessedState.success ? 1 : 0));

    var ui = (String time) => Stack(alignment: Alignment.centerLeft, children: [
          Stack(alignment: Alignment.bottomRight, children: [
            Container(
                width: 244,
                height: 48,
                color: Theme.of(context).canvasColor,
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                        padding: EdgeInsets.fromLTRB(9, 0, 0, 0),
                        child: Text(
                          'Loading dictionaries: '.i18n +
                              '\n' +
                              count.toString() +
                              ' / ' +
                              manager.dictionariesBeingProcessed.length
                                  .toString(),
                          style: TextStyle(fontSize: 18),
                        )))),
            Text(time, style: Theme.of(context).textTheme.overline)
          ]),
          Container(
            child: SizedBox(),
            color: Colors.grey,
            width: 4,
            height: 48,
          ),
        ]);

    Widget fade = SizedBox();

    if (!manager.isRunning &&
        manager.currentOperation == ManagerCurrentOperation.idle &&
        !fadeShown) {
      fadeShown = true;
      var master = Provider.of<MasterDictionary>(context);
      fade = FadeTransition(
          child: ui((master.loadTimeSec.toStringAsFixed(1))),
          opacity: useAnimationController(duration: Duration(seconds: 2))
            ..reverse(from: 0.6));
    }

    return manager.currentOperation == ManagerCurrentOperation.loading &&
            manager.isRunning
        ? Opacity(opacity: 0.3, child: ui(''))
        : fade;
  }
}
