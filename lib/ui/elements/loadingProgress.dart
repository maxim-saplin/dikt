import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dictionaryManager.dart';
import '../../common/i18n.dart';

class DictionaryLoadingProgress extends StatelessWidget {
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
                child: Text('Loading dictionaries: ' +
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
