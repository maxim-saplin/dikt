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

class DictionaryLoadingNoAlign extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var manager = Provider.of<DictionaryManager>(context);

    return manager.currentOperation == ManagerCurrentOperation.loading &&
            manager.isRunning
        ? Container(
            width: 280,
            height: 40,
            color: Colors.grey.withAlpha(128),
            child: Center(
                child: Text('Loading dictionaries: '.i18n +
                    manager.dictionariesBeingProcessed
                        .fold(
                            0,
                            (previousValue, element) =>
                                previousValue +
                                (element.state ==
                                        DictionaryBeingProcessedState.success
                                    ? 1
                                    : 0))
                        .toString() +
                    ' / ' +
                    manager.dictionariesBeingProcessed.length.toString())))
        : Text('');
  }
}
