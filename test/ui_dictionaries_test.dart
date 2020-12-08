import 'package:dikt/common/preferencesSingleton.dart';
import 'package:dikt/models/onlineDictionaries.dart';
import 'package:dikt/ui/screens/dictionaries.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPrefferences extends Mock implements SharedPreferences {}

void main() {
  group('Online Dictionaries', () {
    testWidgets('Empty URL', (WidgetTester tester) async {
      var sp = MockSharedPrefferences();
      await PreferencesSingleton.init(sp);
      when(sp.getString('')).thenAnswer((_) => null);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<OnlineDictionaryManager>(
              create: (context) => OnlineDictionaryManager(FakeOnlineRepo()),
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
            routes: {'/': (context) => Scaffold(body: OnlineDictionaries())},
          ),
        ),
      );

      await tester
          .pump(Duration(milliseconds: 10)); // let progress indicator appear

      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      var field = find.byType(TextFormField);

      expect(field, findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '');

      await tester.pumpAndSettle(Duration(milliseconds: 100));

      final errorFinder = find.text('URL can\'t be empty');

      expect(errorFinder, findsOneWidget);
    });

    test('Empty URL in repo', () {
      final repo = FakeOnlineRepo();

      var res = repo.verifyUrl(null);

      expect(res, 'URL can\'t be empty');
    });
  });
}
