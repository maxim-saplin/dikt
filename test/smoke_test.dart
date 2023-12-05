import 'dart:io';

import 'package:dikt/common/isolate_pool.dart';
import 'package:dikt/main.dart';
import 'package:dikt/models/dictionary_manager.dart';
import 'package:dikt/models/preferences.dart';
import 'package:dikt/ui/elements/lookup.dart';
import 'package:dikt/ui/screens/article.dart';
import 'package:dikt/ui/screens/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:ambilytics/ambilytics.dart' as ambilytics;

import 'finders.dart';
import 'utility.dart';

DictionaryManager? dicManager;
//It makes sense to have different paths for different test files to avoid conflicts when running tests in parallel
const tmpPath = 'test/tmp/smoke';

void main() {
  setUp(() async {
    debugPrint('Setting up SMOKE test');
    // E.g. disabling performance counters in the UI which can break goldens
    widgetTestMode = true;
    initIsolatePool(1);
    await prepareSharedPreferences();

    await pool!.started;

    var tmpDir = Directory(tmpPath);
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    Directory(tmpPath).createSync(recursive: true);

    await DictionaryManager.init(tmpPath);
  });

  tearDown(() {
    try {
      pool!.stop();
      Directory(tmpPath).deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('Smoke test', (WidgetTester tester) async {
    await _smokeTest(tester, false);
  }, skip: true);
  // TODO, don't skip locally, skipping in GH Actions (failing for Windows and Linux for some reasons, works locally)

  //Due to many likely UI changes it is not reasonable to have this test executed, though JIC to peek into the UI generated it might be handy
  // Due to concurrent run can conflict with the smoke test above
  // flutter test '/private/var/user/src/dikt/test/smoke_test.dart' --update-goldens
  testWidgets('Smoke test w. goldens', (WidgetTester tester) async {
    await _smokeTest(tester, false);
  }, skip: true);
}

Future<void> _smokeTest(WidgetTester tester, bool doGoldens) async {
  var defaultPlatform = debugDefaultTargetPlatformOverride;
  debugDefaultTargetPlatformOverride = TargetPlatform
      .windows; // Default is Android, search bar auto focus is broken under widget test environment
  // Fix fonts not visible in widget test golden images
  await loadAppFonts();
  await ambilytics.initAnalytics(
      disableAnalytics: true, measurementId: '1', apiSecret: '2');
  await tester.pumpWidget(const MyApp());
  var scaffold = find.byType(Scaffold);
  expect(scaffold, findsOneWidget);

  // Check what text is in the screen
  // var txt =
  //     tester.widgetList(find.byType(Scaffold).byChildType(Text)).toList();
  // Print to console widget tree
  //debugDumpApp();

  // Wrapping into runAsync() whatever action that happen in isolates or depend on futures
  await tester.runAsync(() async {
    await tester.waitForWidget(scaffold.byChildTextIncludes('Loading'));
    await tester
        .waitForWidget(scaffold.byChildTextIncludes('Type-in text below'));
    //Loadded

    await tester.enterText(find.byType(TextField), 'go');

    // pumpAndSettle duration doesn't give have any real delay providing futures time to complete
    //await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    //await Future.delayed(Duration(milliseconds: 100));

    await tester.waitForWidget(scaffold.byChildTextIncludes(
        '99')); // search box shows number of matches after succesfull lookup
  });

  // App loaded and looked up word
  expect(scaffold.byChildType(Lookup).byChildTextIncludes('go a long way'),
      findsOneWidget);
  // Can fail due to blinking cursor
  if (doGoldens) {
    await expectLater(
        find.byType(MyApp), matchesGoldenFile('smoke_test_lookup.png'));
  }

  await tester.runAsync(() async {
    var item = scaffold.byChildTextIncludes('go about');
    await tester.tap(item);
    var article = scaffold.byChildType(Content);
    // Wait for the article to be composed in future builders and go visible
    await tester.waitForWidget(article.byChildType(Offstage), 20, 20,
        (w) => (w as Offstage).offstage == false);
  });

  // Shpwing article adds a new route and hence 2 scaffolds
  expect(find.byType(Scaffold), findsNWidgets(2));
  scaffold = find.byType(Scaffold).last;

  // Article displayed
  expect(scaffold.byChildType(Offstage).byChildTextIncludes('go about'),
      findsOneWidget);
  if (doGoldens) {
    await expectLater(
        find.byType(MyApp), matchesGoldenFile('smoke_test_article.png'));
  }

  // Check settings dialog is opened
  expect(find.byType(Settings), findsNothing);
  await tester.tap(scaffold.byChildSemantics('Show settings'));
  await tester.waitForWidget(find.byType(Settings));
  // scaffold no longer actual here, might be due to nav
  expect(find.byType(Settings).byChildTextIncludes('Clear History'),
      findsOneWidget);
  if (doGoldens) {
    await expectLater(
        find.byType(MyApp), matchesGoldenFile('smoke_test_settings.png'));
  }

  debugDefaultTargetPlatformOverride = defaultPlatform;

  // You can peek at UI by uncommenting and placing this part (don't use inside runAsync())
  //await expectLater(find.byType(MyApp), matchesGoldenFile('smoke_test.png'));
  // and then running in termina and checkign the generated file:
  // flutter test '/private/var/user/src/dikt/test/smoke_test.dart' --update-goldens
}
