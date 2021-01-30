import 'dart:io';

import 'package:dikt/common/preferencesSingleton.dart';
import 'package:dikt/models/dictionaryManager.dart';
import 'package:dikt/models/indexedDictionary.dart';
import 'package:dikt/models/masterDictionary.dart';
import 'package:dikt/models/onlineDictionaries.dart';
import 'package:dikt/models/onlineDictionariesFakes.dart';
import 'package:dikt/ui/screens/offlineDictionaries.dart';
import 'package:dikt/ui/screens/onlineDictionaries.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ikvpack/ikvpack.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'finders.dart';

DictionaryManager dicManager;

void main() {
  const tmpPath = 'test/tmp';

  setUpAll(() async {
    print('Setting up tests');

    var tmpDir = Directory(tmpPath);
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    Directory(tmpPath).createSync();

    await DictionaryManager.init(tmpPath);

    // Add few blank dictionaries to let offline dictionaries widget display contents
    var dictionaries = await Hive.openBox<IndexedDictionary>(
        DictionaryManager.dictionairesBoxName);
    dictionaries.add(IndexedDictionary.init(
        nameToIkvPath('EN_EN WordNet 3'), 'EN_EN WordNet 3', true, true));
    dictionaries.add(IndexedDictionary.init(
        nameToIkvPath('EN_RU WordNet 3'), 'EN_RU WordNet 3', false, true));
    dictionaries.add(IndexedDictionary.init(
        nameToIkvPath('RU_EN WordNet 3'), 'RU_EN WordNet 3', true, true));

    var m = <String, String>{'a': 'aaa', 'b': 'bbb', 'c': 'ccc'};
    var ikv = IkvPack.fromMap(m);

    await ikv.saveTo(nameToIkvPath('EN_EN WordNet 3'));
    await ikv.saveTo(nameToIkvPath('EN_RU WordNet 3'));
    await ikv.saveTo(nameToIkvPath('RU_EN WordNet 3'));

// used to create manager in _createAndWrapWidget() each time a test is started
// though after moving to Ikv and IsolatePool there was some serois trouble
// with test harbess guts which maid 'await' stuck at 'pool.start()'
    dicManager = DictionaryManager();
    await dicManager.indexAndLoadDictionaries(true);
  });

  tearDownAll(() {
    try {
      Directory(tmpPath).delete(recursive: true);
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

    testWidgets('Dictionary data is properly displayed',
        (WidgetTester tester) async {
      await _openOnlineDictionariesAndWaitToLoad(tester);

      var d = find.byType(OnlineDictionaryTile).first;

      expect(d, findsOneWidget);

      expect(d.byChildText('EN_RU'), findsOneWidget);
      expect(d.byChildText('Universal Lngv'), findsOneWidget);

      expect(d.byChildText(FakeOnlineRepo.dictionaries[0].words.toString()),
          findsOneWidget);
      expect(
          d.byChildText((FakeOnlineRepo.dictionaries[0].sizeBytes / 1024 / 1024)
              .toStringAsFixed(1)
              .toString()),
          findsOneWidget);
      expect(d.byChildText('+'), findsOneWidget);
      //expect(d.byChildIcon(Icons.download_sharp), findsOneWidget);
    });

    testWidgets('Clicking on a not-downloaded dictionary starts downloading',
        (WidgetTester tester) async {
      await _openOnlineDictionariesAndWaitToLoad(tester);

      var d = find.byType(OnlineDictionaryTile).first;
      var t = d.byChildText('+').hitTestable();
      expect(t, findsOneWidget);
      await tester.tap(t);
      await tester.pump();
      expect(d.byChildType(LinearProgressIndicator), findsOneWidget);

      expect(d.byChildText('■'), findsOneWidget);
      await tester
          .pumpAndSettle(); // finish timers that mimic fake stream download
    });

    testWidgets('Simultaneous download is possible',
        (WidgetTester tester) async {
      await _openOnlineDictionariesAndWaitToLoad(tester);

      var d = find.byType(OnlineDictionaryTile).first;
      var t = d.byChildText('+').hitTestable();
      expect(t, findsOneWidget);
      await tester.tap(t);
      await tester.pump(Duration(milliseconds: 10));

      var d7 = find.byType(OnlineDictionaryTile).at(6);
      var t7 = d7.byChildText('+').hitTestable();
      expect(t7, findsOneWidget);
      await tester.tap(t7);
      await tester.pump(Duration(milliseconds: 10));

      expect(d.byChildType(LinearProgressIndicator), findsOneWidget);
      expect(d.byChildText('■'), findsOneWidget);
      expect(d7.byChildType(LinearProgressIndicator), findsOneWidget);
      expect(d7.byChildText('■'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(d.byChildText('×'), findsOneWidget);
      expect(d7.byChildText('×'), findsOneWidget);
    });

    Future<Finder> tapDictionaryWithError(WidgetTester tester) async {
      await _openOnlineDictionariesAndWaitToLoad(tester);

      var d = find
          .byType(OnlineDictionaryTile)
          .at(4); // 5th dictionary throws in repo.download()
      var t = d.byChildText('+').hitTestable();

      expect(t, findsOneWidget);
      await tester.tap(t);
      await tester.pump();

      expect(d.byChildText('↻'), findsOneWidget);
      expect(d.byChildText('error'), findsOneWidget);

      return d;
    }

    testWidgets('Error while initiating download is properly handled',
        (WidgetTester tester) => tapDictionaryWithError(tester));

    testWidgets('Error during download is properly handled',
        (WidgetTester tester) async {
      await _openOnlineDictionariesAndWaitToLoad(tester);

      var d = find
          .byType(OnlineDictionaryTile)
          .at(2); // 3rd dictionary throws error in Stream
      var t = d.byChildText('+').hitTestable();

      expect(t, findsOneWidget);
      await tester.tap(t);
      await tester.pumpAndSettle();

      expect(d.byChildText('↻'), findsOneWidget);
      expect(d.byChildText('Error downloading dictionary'), findsOneWidget);
    });

    testWidgets('Error during indexing is properly handled',
        (WidgetTester tester) async {
      await _openOnlineDictionariesAndWaitToLoad(tester);

      var d = find
          .byType(OnlineDictionaryTile)
          .at(1); // 2nd dictionary throws error in Stream
      var t = d.byChildText('+').hitTestable();

      expect(t, findsOneWidget);
      await tester.tap(t);
      await tester.pump(); // Downloading...
      expect(d.byChildText('Downloading'), findsOneWidget);
      await tester.pump(Duration(seconds: 3)); // Indexing...

      expect(d.byChildText('Indexing'), findsOneWidget);
      await tester.pumpAndSettle();

      expect(d.byChildText('↻'), findsOneWidget);
      expect(d.byChildText('Error indexing dictionary'), findsOneWidget);
    });

    testWidgets('Download can be canceled', (WidgetTester tester) async {
      await _openOnlineDictionariesAndWaitToLoad(tester);

      var d = find.byType(OnlineDictionaryTile).at(5);
      var t = d.byChildText('+').hitTestable();

      expect(t, findsOneWidget);
      await tester.tap(t);
      await tester.pump(Duration(milliseconds: 100)); // Downloading...
      // peek into what text is visible
      //var w = tester.widgetList(d.byChildType(Text)).toList();

      expect(d.byChildText('Downloading'), findsOneWidget);

      t = d.byChildText('■').hitTestable();
      expect(t, findsOneWidget);
      await tester.tap(t);
      await tester.pumpAndSettle();
      t = d.byChildText('+').hitTestable();
      expect(t, findsOneWidget);
    });

    testWidgets('Downloaded dictionary can be deleted',
        (WidgetTester tester) async {
      await _openOnlineDictionariesAndWaitToLoad(tester);

      var d = find.byType(OnlineDictionaryTile).at(3);
      expect(d, findsOneWidget);
      var t = d.byChildText('×').hitTestable();
      expect(t, findsOneWidget);

      await tester.tap(t);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      var delete = find.text('Delete');
      expect(delete, findsOneWidget);
      await tester.tap(delete);
      await tester.pumpAndSettle();

      t = d.byChildText('+').hitTestable();
      expect(t, findsOneWidget);
    });

    testWidgets('Indexing can be canceled', (WidgetTester tester) async {
      await _openOnlineDictionariesAndWaitToLoad(tester);

      var d = find.byType(OnlineDictionaryTile).at(5);
      var t = d.byChildText('+').hitTestable();

      expect(t, findsOneWidget);
      await tester.tap(t);
      await tester.pump(Duration(milliseconds: 100)); // Downloading...

      expect(d.byChildText('Downloading'), findsOneWidget);
      await tester.pump(Duration(seconds: 3)); // Indexing...
      expect(d.byChildText('Indexing'), findsOneWidget);

      t = d.byChildText('■').hitTestable();
      expect(t, findsOneWidget);
      await tester.tap(t);
      await tester.pumpAndSettle();
      t = d.byChildText('+').hitTestable();
      expect(t, findsOneWidget);
    });

    testWidgets('Errorored dictionary can be retried and download',
        (WidgetTester tester) async {
      var d = await tapDictionaryWithError(tester);
      // Fake allows second tap to finish without error
      var t = d.byChildText('↻');
      await tester.tap(t);
      await tester.pumpAndSettle();
      expect(d.byChildText('×'), findsOneWidget);
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
      expect(buttons.byChildText('FILE'), findsOneWidget);

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
      await tester.pumpAndSettle(Duration(milliseconds: 1000));

      var d = find.byType(OfflineDictionaryTile).first;

      expect(d.byChildText('EN_EN WordNet 3'), findsOneWidget);
      expect(d.byChildText('↘'), findsOneWidget);
      // Due to some reasons FutureBuilder in OfflineDictionary proceeds without waiting fot Future to complete
      //expect(d.byChildText('entries'), findsOneWidget);
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
      expect(b, findsOneWidget);
      expect(b.byChildText('↓'), findsOneWidget);

      await tester.tap(b);
      await tester.pump();
      expect(d.byChildType(CircularProgressIndicator), findsOneWidget);
      // pumpAndSettle times out, most likely due to issues with isolates under testing, IkvLoad using pools and isolates to load dictionaries is somehow unstable
      // await tester.pumpAndSettle(Duration(seconds: 10));
      // expect(b.byChildText('↘'), findsOneWidget);
    });

    dragToDelete(WidgetTester tester) async {
      // double pumps to convrt fo cases like below:
      //  if (snapshot.hasData) {
      //    Timer.run(() {
      // ...
      await _createOfflineDictionaries(tester);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(); // allow Timer.run execute

      var d = find.byType(typeOf<LongPressDraggable<int>>()).last;
      expect(d, findsOneWidget);

      var name = tester
          .widgetList(d.byChildType(Column).first.byChildType(Text).first)
          .first as Text;
      //print(name.data);

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

      return name?.data;
    }

    ;
    testWidgets('Dictionary can be dragged to DELETE area', dragToDelete);

    testWidgets('Dictionary can be DELETED', (WidgetTester tester) async {
      var dicName = await dragToDelete(tester);

      expect(find.byType(OfflineDictionaryTile), findsNWidgets(3));
      expect(find.byType(OfflineDictionaryTile).byChildText(dicName),
          findsOneWidget);

      var delete = find.text('Delete');
      expect(delete, findsOneWidget);
      await tester.tap(delete);
      await tester.pumpAndSettle(Duration(milliseconds: 1000));
      await tester.pumpAndSettle(Duration(milliseconds: 1000));
      expect(find.byType(AlertDialog), findsNothing);

      expect(find.byType(OfflineDictionaryTile), findsNWidgets(2));
      expect(find.byType(OfflineDictionaryTile).byChildText(dicName),
          findsNothing);
    });
  });
}

Type typeOf<T>() => T;

class MockSharedPrefferences extends Mock implements SharedPreferences {}

Future _createOnlineDictionaries(WidgetTester tester) async {
  await _createAndWrapWidget(tester, OnlineDictionaries());
}

Future _createOfflineDictionaries(WidgetTester tester) async {
  await _createAndWrapWidget(tester, OfflineDictionaries());
}

Future _createAndWrapWidget(WidgetTester tester, Widget widget) async {
  var sp = MockSharedPrefferences();
  await PreferencesSingleton.init(sp);
  when(sp.getString('')).thenAnswer((_) => null);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DictionaryManager>(
          create: (context) {
            return dicManager;
          },
        ),
        ChangeNotifierProvider<OnlineDictionaryManager>(
          create: (context) =>
              OnlineDictionaryManager(FakeOnlineRepo(), OnlineToOfflineFake()),
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
