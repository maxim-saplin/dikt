import 'package:flutter/material.dart';

import '../models/dictionaryManager.dart';

class ManagerState extends StatelessWidget {
  const ManagerState({
    Key key,
    @required this.manager,
  }) : super(key: key);

  final DictionaryManager manager;

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text(manager.currentOperation ==
                ManagerCurrentOperation.preparing
            ? 'One moment please'
            : (manager.currentOperation == ManagerCurrentOperation.indexing
                    ? 'Indexing [' +
                        manager.dictionariesBeingProcessed.length.toString() +
                        '] dictionaries'
                    : 'Loading [' +
                        manager.dictionariesBeingProcessed.length.toString() +
                        '] dictionaries') +
                '\n' +
                manager.dictionariesBeingProcessed.fold(
                    '',
                    (accum, value) =>
                        accum +
                        '\n' +
                        value.name +
                        ': ' +
                        (value.state == DictionaryBeingProcessedState.inprogress
                            ? (value.progressPercent == null
                                ? '⌛'
                                : value.progressPercent.toString() + '%')
                            : (value.state ==
                                    DictionaryBeingProcessedState.pending
                                ? '...'
                                : (value.state ==
                                        DictionaryBeingProcessedState.success
                                    ? 'OK'
                                    : 'ERROR'))))));
  }
}
