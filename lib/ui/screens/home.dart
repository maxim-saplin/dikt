import 'package:flutter/material.dart';

import '../panes/lookup.dart';

int wideNarrowThreshold = 500;

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= wideNarrowThreshold) {
        return Row(children: const [
          Lookup(searchBarTopRounded: false),
          Center(child: Text('Article here'))
        ]);
      }
      return const Lookup(searchBarTopRounded: true);
    });
  }
}
