import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dictionary_manager.dart';
import '../../common/i18n.dart';

class ManagerState extends StatelessWidget {
  final bool _onlyErrors;

  const ManagerState([this._onlyErrors = false]);

  @override
  Widget build(BuildContext context) {
    var manager = Provider.of<DictionaryManager>(context);

    return Align(
        alignment: Alignment.topLeft,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(manager.currentOperation == ManagerCurrentOperation.preparing
                  ? 'One moment please'.i18n
                  : (manager.currentOperation ==
                              ManagerCurrentOperation.indexing
                          ? 'indexing_dic'.i18n.fill([
                              manager.dictionariesBeingProcessed
                                  .where((d) =>
                                      d.state ==
                                          DictionaryBeingProcessedState
                                              .success ||
                                      d.state ==
                                          DictionaryBeingProcessedState.error)
                                  .length
                                  .toString(),
                              manager.dictionariesBeingProcessed.length
                                  .toString()
                            ])
                          : 'loading_dic'.i18n.fill([
                              manager.dictionariesBeingProcessed
                                  .where((d) =>
                                      d.state ==
                                          DictionaryBeingProcessedState
                                              .success ||
                                      d.state ==
                                          DictionaryBeingProcessedState.error)
                                  .length
                                  .toString(),
                              manager.dictionariesBeingProcessed.length
                                  .toString()
                            ])) +
                      '\n' +
                      manager.dictionariesBeingProcessed
                          .where((d) => !_onlyErrors
                              ? true
                              : d.state == DictionaryBeingProcessedState.error)
                          .fold(
                              '',
                              (accum, value) =>
                                  accum +
                                  '\n' +
                                  value.name +
                                  ': ' +
                                  (value.state ==
                                          DictionaryBeingProcessedState
                                              .inprogress
                                      ? (value.progressPercent == null
                                          ? '⌛'
                                          : value.progressPercent.toString() +
                                              '%')
                                      : (value.state ==
                                              DictionaryBeingProcessedState
                                                  .pending
                                          ? '...'
                                          : (value.state ==
                                                  DictionaryBeingProcessedState
                                                      .success
                                              ? 'OK'
                                              : 'ERROR'.i18n)))))
            ]));
  }
}
