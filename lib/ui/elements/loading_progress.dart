import 'package:dikt/models/master_dictionary.dart';
import 'package:dikt/ui/elements/manager_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import '../../models/dictionary_manager.dart';
import '../../common/i18n.dart';

class DictionaryIndexingOrLoading extends StatelessWidget {
  const DictionaryIndexingOrLoading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!fadeShown) {
      var manager = Provider.of<DictionaryManager>(context);
      switch (manager.currentOperation) {
        // case ManagerCurrentOperation.loading:
        //   return DictionaryLoading();
        case ManagerCurrentOperation.indexing:
          return const Padding(
              padding: EdgeInsets.all(12), child: ManagerState());
        default:
          return const DictionaryLoading();
      }
    }

    return const SizedBox();
  }
}

class DictionaryIndexing extends StatelessWidget {
  const DictionaryIndexing({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!fadeShown) {
      var manager = Provider.of<DictionaryManager>(context);
      return manager.currentOperation == ManagerCurrentOperation.indexing
          ? const Padding(padding: EdgeInsets.all(12), child: ManagerState())
          : const Text('');
    }

    return const SizedBox();
  }
}

class DictionaryLoading extends StatelessWidget {
  const DictionaryLoading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Align(
        alignment: Alignment.topCenter,
        child: Padding(
            padding: EdgeInsets.fromLTRB(0, 120, 0, 0),
            child: DictionaryLoadingNoAlign()));
  }
}

bool fadeShown = false;

class DictionaryLoadingNoAlign extends HookWidget {
  const DictionaryLoadingNoAlign({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var manager = Provider.of<DictionaryManager>(context);

    var count = manager.dictionariesBeingProcessed.fold(
        0,
        (dynamic previousValue, element) =>
            previousValue +
            (element.state == DictionaryBeingProcessedState.success ? 1 : 0));

    Widget ui(String time) => Stack(alignment: Alignment.centerLeft, children: [
          Stack(alignment: Alignment.bottomRight, children: [
            Container(
                width: 244,
                height: 48,
                color: Theme.of(context).canvasColor,
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(9, 0, 0, 0),
                        child: Text(
                          '${'Loading dictionaries: '.i18n}\n$count / ${manager.dictionariesBeingProcessed.length}',
                          style: const TextStyle(fontSize: 18),
                        )))),
            Text(time, style: Theme.of(context).textTheme.overline)
          ]),
          Container(
            color: Colors.grey,
            width: 4,
            height: 48,
            child: const SizedBox(),
          ),
        ]);

    Widget fade = const SizedBox();

    if (!manager.isRunning &&
        manager.currentOperation == ManagerCurrentOperation.idle &&
        !fadeShown) {
      fadeShown = true;
      var master = Provider.of<MasterDictionary>(context);
      fade = FadeTransition(
          opacity: useAnimationController(duration: const Duration(seconds: 3))
            ..reverse(from: 0.6),
          child: ui((master.loadTimeSec.toStringAsFixed(1))));
    }

    return manager.currentOperation == ManagerCurrentOperation.loading &&
            manager.isRunning
        ? Opacity(opacity: 0.3, child: ui(''))
        : fade;
  }
}
