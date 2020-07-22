import 'package:flutter/material.dart';
import 'package:reorderables/reorderables.dart';
import 'package:provider/provider.dart';
import '../models/dictionaryManager.dart';

class Dictionaries extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ScrollController _scrollController =
        PrimaryScrollController.of(context) ?? ScrollController();

    var manager = Provider.of<DictionaryManager>(context);

    void _onReorder(int oldIndex, int newIndex) {
      manager.reorder(oldIndex, newIndex);
    }

    return Stack(children: [
      Padding(
          padding: EdgeInsets.fromLTRB(12, 50, 12, 60),
          child: CustomScrollView(
            controller: _scrollController,
            shrinkWrap: true,
            slivers: <Widget>[
              ReorderableSliverList(
                  delegate: ReorderableSliverChildListDelegate(manager
                      .dictionariesReady
                      .map((e) => Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.check_box_outline_blank,
                                      size: 20),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_forever, size: 20),
                                  onPressed: () {},
                                ),
                                Expanded(
                                    child: Container(
                                        height: 55,
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(e.name,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .caption),
                                              Text(
                                                e.box.length.toString() +
                                                    ' entries, ' +
                                                    e.fileSizeMb
                                                        .toStringAsFixed(1) +
                                                    "MB",
                                                overflow: TextOverflow.fade,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .subtitle2,
                                              )
                                            ]))),
                              ]))
                      .toList()),
                  onReorder: _onReorder)
            ],
          )),
      Container(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
          height: 50.0,
          child: Text(
            "Dictionaries",
            style: Theme.of(context).textTheme.headline6,
          )),
      Positioned(
        bottom: 0.0,
        left: 0.0,
        right: 0.0,
        child: Container(
          color: Theme.of(context).cardColor,
          padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
          height: 60,
          child: Center(
              child: OutlineButton(
            child: Text('+ Add Dictionary'),
            onPressed: () {},
          )),
        ),
      )
    ]);
  }
}
