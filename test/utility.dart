import 'package:dikt/common/preferences_singleton.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void prepareSharedPreferences() async {
  SharedPreferences.setMockInitialValues({});
  var sp = await SharedPreferences.getInstance();
  PreferencesSingleton.init(sp);
}

extension TesterExtensions on WidgetTester {
  /// Polls with given period and fails test should the widget not be found after [numberOfPolls]
  Future<void> waitForWidget(Finder finder,
      [int pollingPeriodMs = 16, int numberOfPolls = 50]) async {
    for (var i = 0; i < numberOfPolls; i++) {
      if (finder.evaluate().isNotEmpty) {
        break;
      }
      await pumpAndSettle();
      await Future.delayed(Duration(milliseconds: pollingPeriodMs));
    }

    expect(finder, findsOneWidget);
  }
}
