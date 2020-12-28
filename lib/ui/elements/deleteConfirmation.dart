import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../common/i18n.dart';

void confirmAndDelete(BuildContext context, String name, Function onDelete) {
  showDialog(
      context: context,
      barrierColor: !kIsWeb ? Colors.transparent : Colors.black54,
      routeSettings: RouteSettings(name: '/delete_dic'),
      builder: (context) => AlertDialog(
            insetPadding: EdgeInsets.all(20),
            content: Text('Delete_dic'.i18n.fill([name])),
            actions: [
              FlatButton(
                child: Text('Delete'.i18n),
                onPressed: () {
                  onDelete();
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Cancel'.i18n),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          ));
}
