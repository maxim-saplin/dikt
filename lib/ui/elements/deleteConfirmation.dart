import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../common/i18n.dart';

/// Asks 3 times for confirmation after that it silently does the action

int _counter = 0;
DateTime _lastTimeCalled = DateTime.now();

void confirmAndDelete(BuildContext context, String name, Function onDelete) {
  if (_counter < 3) {
    _counter++;
    _lastTimeCalled = DateTime.now();
  } else if (DateTime.now().difference(_lastTimeCalled).inSeconds > 60) {
    _counter = 0;
    _lastTimeCalled = DateTime.now();
  } else {
    _lastTimeCalled = DateTime.now();
    onDelete();
    return;
  }

  showDialog(
      context: context,
      barrierColor: !kIsWeb ? Colors.transparent : Colors.black54,
      routeSettings: RouteSettings(name: '/delete_dic'),
      builder: (context) => AlertDialog(
            insetPadding: EdgeInsets.all(10),
            content: Text('Delete_dic'.i18n.fill([name])),
            actions: [
              TextButton(
                child: Text('Delete'.i18n),
                onPressed: () {
                  onDelete();
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Cancel'.i18n),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          ));
}
