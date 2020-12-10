import 'dart:io';

import 'package:dikt/common/preferencesSingleton.dart';
import 'package:dikt/models/dictionaryManager.dart';
import 'package:dikt/models/indexedDictionary.dart';
import 'package:dikt/models/onlineDictionaries.dart';
import 'package:dikt/ui/screens/dictionaries.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'finders.dart';

void main() {
  const hivePath = './hive_test';

  setUpAll(() async {
    print('Setting up tests');

    await DictionaryManager.init(hivePath);

    var dictionaries = await Hive.openBox<IndexedDictionary>(
        DictionaryManager.dictionairesBoxName);
    dictionaries.add(IndexedDictionary.init(
        nameToBoxName('EN_EN WordNet 3'), 'EN_EN WordNet 3', true));
    await Hive.openLazyBox(nameToBoxName('EN_EN WordNet 3'));
  });

  tearDownAll(() {
    try {
      Directory(hivePath).delete(recursive: true);
    } catch (_) {}
  });

  group('Online Dictionaries', () {
    testWidgets('Empty URL shows error', (WidgetTester tester) async {
      await _openOnlineDictionariesAndWaitToLoad(tester);

      var field = find.byType(TextFormField);
      expect(field, findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '');

      await tester.pumpAndSettle(Duration(milliseconds: 100));

      final errorFinder = find.text('URL can\'t be empty');

      expect(errorFinder, findsOneWidget);
    });

    testWidgets('Default test URL loads 10 dictionaries',
        (WidgetTester tester) async {
      await _openOnlineDictionariesAndWaitToLoad(tester);

      expect(find.byType(OnlineDictionaryTile), findsNWidgets(10));
    });

    testWidgets('Second test URL loads 5 dictionaries',
        (WidgetTester tester) async {
      await _openOnlineDictionariesAndWaitToLoad(tester);

      var field = find.byType(TextFormField);
      expect(field, findsOneWidget);
      await tester.enterText(
          find.byType(TextFormField), FakeOnlineRepo.secondUrl);
      await tester.pumpAndSettle(Duration(milliseconds: 100));

      expect(find.byType(OnlineDictionaryTile), findsNWidgets(5));
    });

    testWidgets('Invalid URL shows error', (WidgetTester tester) async {
      await _openOnlineDictionariesAndWaitToLoad(tester);

      var field = find.byType(TextFormField);
      expect(field, findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'htts://');
      await tester.pumpAndSettle(Duration(milliseconds: 100));

      expect(find.text('Invalid URL'), findsOneWidget);
    });

    testWidgets('Wrong URL shows repo unavailable',
        (WidgetTester tester) async {
      await _openOnlineDictionariesAndWaitToLoad(tester);

      var field = find.byType(TextFormField);
      expect(field, findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'https://ipfs.com');
      await tester.pumpAndSettle(Duration(milliseconds: 100));

      expect(find.text('Repository not available'), findsOneWidget);
    });
  });

  group('Offline Dictionaries', () {
    testWidgets('Import JSON and Online buttons visible and enabled',
        (WidgetTester tester) async {
      await _createOfflineDictionaries(tester);
      await tester.pump();

      var buttons = find.byType(OutlinedButton).hitTestable();
      expect(buttons, findsNWidgets(2));

      //var text = buttons.first.byChildType(Text);
      expect(buttons.first.byChildText('JSON'), findsOneWidget);

      expect(buttons.first.byChildText('Online'), findsOneWidget);
    });
  });
}

class MockSharedPrefferences extends Mock implements SharedPreferences {}

Future _createOnlineDictionaries(WidgetTester tester) async {
  await _createWidget(tester, OnlineDictionaries());
}

Future _createOfflineDictionaries(WidgetTester tester) async {
  await _createWidget(tester, OfflineDictionaries());
}

Future _createWidget(WidgetTester tester, Widget widget) async {
  var sp = MockSharedPrefferences();
  await PreferencesSingleton.init(sp);
  when(sp.getString('')).thenAnswer((_) => null);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<OnlineDictionaryManager>(
          create: (context) => OnlineDictionaryManager(FakeOnlineRepo()),
        ),
        ChangeNotifierProvider<DictionaryManager>(
          create: (context) => DictionaryManager(),
        )
      ],
      child: MaterialApp(
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          const Locale('en', ''),
          const Locale('be', ''),
          const Locale('ru', ''),
        ],
        initialRoute: '/',
        routes: {'/': (context) => Scaffold(body: widget)},
      ),
    ),
  );
}

Future _openOnlineDictionariesAndWaitToLoad(WidgetTester tester) async {
  await _createOnlineDictionaries(tester);

  await tester
      .pump(Duration(milliseconds: 10)); // let progress indicator appear

  expect(find.byType(LinearProgressIndicator), findsOneWidget);

  await tester.pumpAndSettle();
}
