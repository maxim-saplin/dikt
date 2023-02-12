import 'dart:io';

import 'package:dikt/common/isolate_pool.dart';
import 'package:dikt/main.dart';
import 'package:dikt/models/dictionary_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'finders.dart';
import 'utility.dart';

DictionaryManager? dicManager;
//It makes sense to have different paths for different test files to avoid conflicts when running tests in parallel
const tmpPath = 'test/tmp/smoke';

void main() {
  setUpAll(() async {
    debugPrint('Setting up SMOKE test');
    initIsolatePool();
    prepareSharedPreferences();
    await pool!.started;

    var tmpDir = Directory(tmpPath);
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    Directory(tmpPath).createSync(recursive: true);

    await DictionaryManager.init(tmpPath);
  });

  tearDownAll(() {
    try {
      pool!.stop();
      Directory(tmpPath).delete(recursive: true);
    } catch (_) {}
  });

  testWidgets('Smoke test', (WidgetTester tester) async {
    var defaultPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform
        .macOS; // Default is Android, search bar auto focus is broken under widget test environment
    // Fix fonts not visible in widget test golden images
    await loadAppFonts();
    await tester.pumpWidget(MyApp());
    var scaffold = find.byType(Scaffold);
    expect(scaffold, findsOneWidget);

    // Check what text is in the screen
    // var txt =
    //     tester.widgetList(find.byType(Scaffold).byChildType(Text)).toList();
    // Print to console widget tree
    //debugDumpApp();

    // Wrapping into runAsync() whatever action that happen in isolates or depend on futures
    await tester.runAsync(() async {
      await tester.waitForWidget(scaffold.byChildText('Loading'));
      await tester.waitForWidget(scaffold.byChildText('Type-in text below'));
      //Loadded

      await tester.enterText(find.byType(TextField), 'go');

      // pumpAndSettle duration doesn't give have any real delay providing futures time to complete
      //await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      //await Future.delayed(Duration(milliseconds: 100));

      await tester.waitForWidget(scaffold.byChildText(
          '99')); // search box shows number of matches after succesfull lookup
    });

    // Loaded and looked up word
    await expectLater(
        find.byType(MyApp), matchesGoldenFile('smoke_test_lookup.png'));

    //await expectLater(find.byType(MyApp), matchesGoldenFile('smoke_test.png'));

    debugDefaultTargetPlatformOverride = defaultPlatform;

    // You can peek at UI by uncommenting and placing this part (don't use inside runAsync())
    //await expectLater(find.byType(MyApp), matchesGoldenFile('smoke_test.png'));
    // and then running in termina and checkign the generated file:
    // flutter test '/private/var/user/src/dikt/test/smoke_test.dart' --update-goldens
  });
}
