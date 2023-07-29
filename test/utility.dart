import 'package:dikt/common/preferences_singleton.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

@visibleForTesting
Future<void> prepareSharedPreferences() async {
  SharedPreferences.setMockInitialValues({'analytics': false});
  var sp = await SharedPreferences.getInstance();
  await PreferencesSingleton.init(sp);
}

extension TesterExtensions on WidgetTester {
  /// Polls with given period and fails test should the widget not be found after [numberOfPolls]
  Future<void> waitForWidget(Finder finder,
      [int pollingPeriodMs = 16,
      int numberOfPolls = 50,
      bool Function(Widget widget)? testCondition]) async {
    // Hack that allows to determine if the method is executed inside or outside of runAsync()
    // await Future.delayed - won't work if not inside runAsync()
    bool isRanAsync = false;
    try {
      await binding.runAsync(() async {});
    } catch (_) {
      isRanAsync = true;
    }

    for (var i = 0; i < numberOfPolls; i++) {
      if (finder.evaluate().isNotEmpty) {
        if (testCondition == null) {
          break;
        }
        if (testCondition(finder.evaluate().first.widget)) {
          break;
        }
      }
      await pumpAndSettle();
      if (isRanAsync) {
        await Future.delayed(Duration(milliseconds: pollingPeriodMs));
      }
    }

    expect(finder, findsOneWidget);
    if (testCondition != null) {
      expect(testCondition(finder.evaluate().first.widget), true);
    }
  }
}
