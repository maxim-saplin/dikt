import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dictionaryManager.dart';
import '../common/i18n.dart';

class ManagerState extends StatelessWidget {
  const ManagerState({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var manager = Provider.of<DictionaryManager>(context);

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(manager.currentOperation == ManagerCurrentOperation.preparing
              ? 'One moment please'.i18n
              : (manager.currentOperation == ManagerCurrentOperation.indexing
                      ? 'indexing_dic'.i18n.fill([
                          manager.dictionariesBeingProcessed.length.toString()
                        ])
                      : 'loading_dic'.i18n.fill([
                          manager.dictionariesBeingProcessed.length.toString()
                        ])) +
                  '\n' +
                  manager.dictionariesBeingProcessed.fold(
                      '',
                      (accum, value) =>
                          accum +
                          '\n' +
                          value.name +
                          ': ' +
                          (value.state ==
                                  DictionaryBeingProcessedState.inprogress
                              ? (value.progressPercent == null
                                  ? '⌛'
                                  : value.progressPercent.toString() + '%')
                              : (value.state ==
                                      DictionaryBeingProcessedState.pending
                                  ? '...'
                                  : (value.state ==
                                          DictionaryBeingProcessedState.success
                                      ? 'OK'
                                      : 'ERROR'.i18n)))))
        ]);
  }
}
