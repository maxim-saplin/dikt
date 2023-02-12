import 'dart:io';

import 'package:dikt/common/isolate_pool.dart';
import 'package:dikt/common/preferences_singleton.dart';
import 'package:dikt/main.dart';
import 'package:dikt/models/dictionary_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'finders.dart';
import 'utility.dart';

DictionaryManager? dicManager;
const tmpPath = 'test/tmp';

void main() {
  setUpAll(() async {
    debugPrint('Setting up SMOKE test');
    initIsolatePool();
    prepareSharedPreferences();
    await pool!.started;

    var tmpDir = Directory(tmpPath);
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    Directory(tmpPath).createSync();

    await DictionaryManager.init(tmpPath);
  });

  tearDownAll(() {
    try {
      Directory(tmpPath).delete(recursive: true);
      pool!.stop();
    } catch (_) {}
  });

  testWidgets('Smoke test', (WidgetTester tester) async {
    var defaultPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform
        .macOS; // Default is Android, search bar auto focus is broken under widget test environment
    // Fix fonts not visible in widget test golden images
    await loadAppFonts();
    await tester.runAsync(() async {
      await tester.pumpWidget(MyApp());
      var scaffold = find.byType(Scaffold);
      expect(scaffold, findsOneWidget);

      //
      // await Future.delayed(const Duration(seconds: 1));
      // await tester.pumpAndSettle();
      // await Future.delayed(const Duration(seconds: 1));

      // Check what text is in the screen
      // var txt =
      //     tester.widgetList(find.byType(Scaffold).byChildType(Text)).toList();
      // Print to console widget tree
      //debugDumpApp();

      await tester.waitForWidget(scaffold.byChildText('Type-in text below'));
      //expect(scaffold.byChildText('Type-in text below'), findsOneWidget);
    });

    debugDefaultTargetPlatformOverride = defaultPlatform;
    // You can peek at UI by uncommenting this part and checkign the generated file
    // flutter test '/private/var/user/src/dikt/test/smoke_test.dart' --update-goldens
    //await expectLater(find.byType(MyApp), matchesGoldenFile('smoke_test.png'));
  });
}
