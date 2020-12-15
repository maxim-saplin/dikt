import 'package:dikt/ui/elements/managerState.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dictionaryManager.dart';
import '../../common/i18n.dart';

class DictionaryIndexingOrLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var manager = Provider.of<DictionaryManager>(context);
    switch (manager.currentOperation) {
      case ManagerCurrentOperation.loading:
        return DictionaryLoading();
      case ManagerCurrentOperation.indexing:
        return Padding(padding: EdgeInsets.all(12), child: ManagerState());
      default:
        return Text('');
    }
  }
}

class DictionaryIndexing extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var manager = Provider.of<DictionaryManager>(context);
    return manager.currentOperation == ManagerCurrentOperation.indexing
        ? Padding(padding: EdgeInsets.all(12), child: ManagerState())
        : Text('');
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

String hashSpinner(int x) {
  if (x % 4 == 0) return '/';
  if (x % 4 == 1) return '|';
  if (x % 4 == 2) return '\\';
  return '-';
}

class DictionaryLoadingNoAlign extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var manager = Provider.of<DictionaryManager>(context);

    var count = manager.dictionariesBeingProcessed.fold(
        0,
        (previousValue, element) =>
            previousValue +
            (element.state == DictionaryBeingProcessedState.success ? 1 : 0));

    return manager.currentOperation == ManagerCurrentOperation.loading &&
            manager.isRunning
        ? Opacity(
            opacity: 0.3,
            child: Stack(alignment: Alignment.bottomCenter, children: [
              Container(
                  width: 256,
                  height: 36,
                  color: Colors.transparent,
                  child: Center(
                      child: Text(
                    'Loading dictionaries: '.i18n +
                        count.toString() +
                        ' ' +
                        hashSpinner(count) +
                        ' ' +
                        manager.dictionariesBeingProcessed.length.toString(),
                    style: TextStyle(fontSize: 18),
                  ))),
              Container(
                child: SizedBox(),
                color: Colors.grey,
                width: 256,
                height: 3,
              ),
            ]))
        : Text('');
  }
}
