import 'dart:io';
import 'dart:typed_data';

import 'package:dikt/common/preferencesSingleton.dart';
import 'package:dikt/models/dictionaryManager.dart';
import 'package:dikt/models/indexedDictionary.dart';
import 'package:dikt/models/masterDictionary.dart';
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
        nameToBoxName('EN_EN WordNet 3'), 'EN_EN WordNet 3', true, true));
    dictionaries.add(IndexedDictionary.init(
        nameToBoxName('EN_RU WordNet 3'), 'EN_RU WordNet 3', false, true));
    dictionaries.add(IndexedDictionary.init(
        nameToBoxName('RU_EN WordNet 3'), 'RU_EN WordNet 3', true, true));

    await Hive.openLazyBox<Uint8List>(nameToBoxName('EN_EN WordNet 3'));
    await Hive.openLazyBox<Uint8List>(nameToBoxName('EN_RU WordNet 3'));
    await Hive.openLazyBox<Uint8List>(nameToBoxName('RU_EN WordNet 3'));
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

    testWidgets('Dictionary data is displayed', (WidgetTester tester) async {
      await _openOnlineDictionariesAndWaitToLoad(tester);

      var d = find.byType(OnlineDictionaryTile).first;

      expect(d, findsOneWidget);
      expect(
          d.byChildText(FakeOnlineRepo.dictionaries[0].name), findsOneWidget);
      expect(d.byChildText(FakeOnlineRepo.dictionaries[0].words.toString()),
          findsOneWidget);
      expect(
          d.byChildText((FakeOnlineRepo.dictionaries[0].sizeBytes / 1024 / 1024)
              .toStringAsFixed(1)
              .toString()),
          findsOneWidget);
      expect(d.byChildIcon(Icons.download_sharp), findsOneWidget);
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
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(); // allow Timer.run execute

      var buttons = find.byType(OutlinedButton).hitTestable();
      expect(buttons, findsNWidgets(2));

      //var text = buttons.first.byChildType(Text);
      expect(buttons.byChildText('JSON'), findsOneWidget);

      expect(buttons.byChildText('Online'), findsOneWidget);
    });

    testWidgets('Dictionaries are displayed on show',
        (WidgetTester tester) async {
      await _createOfflineDictionaries(tester);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(); // allow Timer.run execute
      var d = find.byType(OfflineDictionaryTile);

      expect(d, findsNWidgets(3));
    });

    testWidgets('Dictionary data is displayed', (WidgetTester tester) async {
      await _createOfflineDictionaries(tester);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(); // allow Timer.run execute

      var d = find.byType(OfflineDictionaryTile).first;

      expect(d.byChildText('EN_EN WordNet 3'), findsOneWidget);
      expect(d.byChildText('↘'), findsOneWidget);
      expect(d.byChildText('entries'), findsOneWidget);
    });

    testWidgets('Dictionary can be disabled', (WidgetTester tester) async {
      await _createOfflineDictionaries(tester);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(); // allow Timer.run execute

      var d = find.byType(OfflineDictionaryTile).first;
      expect(d, findsOneWidget);
      var b = d.byChildType(FlatButton);
      expect(b.byChildText('↘'), findsOneWidget);

      await tester.tap(b);
      await tester.pumpAndSettle();
      expect(b.byChildText('↓'), findsOneWidget);
    });

    testWidgets('Dictionary can be enabled', (WidgetTester tester) async {
      await _createOfflineDictionaries(tester);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(); // allow Timer.run execute

      var d = find.byType(OfflineDictionaryTile).at(1);
      expect(d, findsOneWidget);
      var b = d.byChildType(FlatButton);
      expect(b.byChildText('↓'), findsOneWidget);

      await tester.tap(b);
      await tester.pumpAndSettle();
      expect(b.byChildText('↘'), findsOneWidget);
    });

    testWidgets('Dictionary can be dragged to DELETE area',
        (WidgetTester tester) async {
      // double pumps to convrt fo cases like below:
      //  if (snapshot.hasData) {
      //    Timer.run(() {
      // ...
      await _createOfflineDictionaries(tester);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(); // allow Timer.run execute

      var d = find.byType(typeOf<LongPressDraggable<int>>()).last;
      expect(d, findsOneWidget);

      var firstLocation = tester.getCenter(d);
      var gesture = await tester.startGesture(firstLocation, pointer: 7);
      await tester.pumpAndSettle(Duration(milliseconds: 1000));
      await tester.pumpAndSettle(Duration(milliseconds: 1000));

      var delete = find.text('DELETE');
      expect(delete, findsOneWidget);

      var secondLocation = tester.getCenter(delete);
      await gesture.moveTo(secondLocation);
      await tester.pumpAndSettle(Duration(milliseconds: 1000));
      await tester.pumpAndSettle(Duration(milliseconds: 1000));
      await gesture.up();
      await tester.pumpAndSettle(Duration(milliseconds: 1000));
      await tester.pumpAndSettle(Duration(milliseconds: 1000));

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    // testWidgets('Drag and drop - long press draggable, short press',
    //     (WidgetTester tester) async {
    //   final List<String> events = <String>[];
    //   Offset firstLocation, secondLocation;

    //   await tester.pumpWidget(MaterialApp(
    //     home: Column(
    //       children: <Widget>[
    //         const LongPressDraggable<int>(
    //           data: 1,
    //           child: Text('Source'),
    //           feedback: Text('Dragging'),
    //         ),
    //         DragTarget<int>(
    //           builder: (BuildContext context, List<int> data,
    //               List<dynamic> rejects) {
    //             return const Text('Target');
    //           },
    //           onAccept: (int data) {
    //             events.add('drop');
    //           },
    //           onAcceptWithDetails: (DragTargetDetails<int> _) {
    //             events.add('details');
    //           },
    //         ),
    //       ],
    //     ),
    //   ));

    //   expect(events, isEmpty);
    //   expect(find.text('Source'), findsOneWidget);
    //   expect(find.text('Target'), findsOneWidget);

    //   expect(events, isEmpty);

    //   //var dd = find.text('Source');

    //   var dd = find.byType(typeOf<LongPressDraggable<int>>());

    //   await tester.tap(dd);
    //   expect(events, isEmpty);

    //   firstLocation = tester.getCenter(dd);
    //   final TestGesture gesture =
    //       await tester.startGesture(firstLocation, pointer: 7);
    //   await tester.pump();

    //   secondLocation = tester.getCenter(find.text('Target'));
    //   await gesture.moveTo(secondLocation);
    //   await tester.pump();

    //   expect(events, isEmpty);
    //   await gesture.up();
    //   await tester.pump();
    //   expect(events, isEmpty);
    // });
  });
}

Type typeOf<T>() => T;

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
          create: (context) {
            var dicManager = DictionaryManager();

            dicManager.indexAndLoadDictionaries(true);
            return dicManager;
          },
        ),
        ChangeNotifierProvider<MasterDictionary>(create: (context) {
          var master = MasterDictionary();
          return master;
        })
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
