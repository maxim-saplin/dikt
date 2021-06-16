import 'package:flutter/widgets.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsObserver extends RouteObserver {
  AnalyticsObserver({required this.analytics});

  final FirebaseAnalytics analytics;

  void _sendScreenView(Route<dynamic> route) {
    final String screenName = route.settings.name! +
        (route.settings.arguments != null
            ? '/' + (route.settings.arguments as String)
            : '');

    //print('Setting screen to ' + screenName);
    // analytics
    //     .logEvent(name: 'navigation', parameters: {'screen': screenName});
    analytics.setCurrentScreen(
        screenName: screenName, screenClassOverride: screenName);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _sendScreenView(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _sendScreenView(newRoute!);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _sendScreenView(previousRoute!);
  }
}
