import 'dart:async';
import 'dart:ui';

import 'package:dikt/common/i18n.dart';
import 'package:dikt/ui/screens/dictionaries.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:provider/provider.dart';

import '../models/history.dart';
import '../models/master_dictionary.dart';

// Absttraction over Navigator API providing access to navigation methods
// via simple methods without the need to user context as a params
// Problems:
// - Moving to navigatorKey and current contextnbreaks ModaleRoute.of() technique for getting current route (no other way googled so far)
// - Routes are pages with own state which kind of breaks the Web/SPA approach with routes not updating state of the whole page when travling to # addrtesses - brought trouble with my 2 pane layout when different routes had same 2 pane layout but different widthes due to manual split view resizing
// - Going back doesn't invalidate/rebuild widgets, state might be stale, need to triger rebuild manually
// - Need to have own subclass of navigation observer to get hold of nav history/stack
class Routes {
  static BuildContext get currentContext => navigator.currentContext!;

  static final StackObserver observer = StackObserver();

  /// Using this global key to avoid mess with build contexts and potential "Looking up a deactivated widget's ancestor is unsafe" errors
  static final GlobalKey<NavigatorState> navigator =
      GlobalKey<NavigatorState>();

  static ModalRoute get currentRoute => observer._routeStack.last as ModalRoute;

  static const String home = '/';
  static const String article = '/article';
  static const String dictionariesOnline = '/dictionariesOnline';
  static const String dictionariesOffline = '/dictionaries';

  static void goBack() {
    var route = currentRoute;
    if (route.settings.name == home) {
      return;
    }

    Navigator.of(currentContext).pop();
  }

  static void showArticle(String word, [bool addToHistory = true]) {
    var route = currentRoute;
    if (route.settings.name == article &&
        (route.settings.arguments as String) == word) {
      return;
    }

    Route? routeToDelete;

    for (var r in observer._routeStack) {
      if (r.settings.name == article &&
          (r.settings.arguments as String) == word) {
        routeToDelete = r;
        break;
      }
    }

    if (routeToDelete != null) {
      Navigator.of(currentContext).removeRoute(routeToDelete);
    }

    if (addToHistory) {
      var history = Provider.of<History>(currentContext, listen: false);

      history.addWord(word);
    }
    var dictionary =
        Provider.of<MasterDictionary>(currentContext, listen: false);
    dictionary.selectedWord = word;

    Navigator.of(currentContext)
        .pushNamed(Routes.article, arguments: word)
        // Force reload when home page is reached, e.g. to update the lookup list
        .whenComplete(() {
      if (currentRoute.settings.name == home) {
        Navigator.of(currentContext).pushReplacementNamed(home);
      }
    });
  }

  static void showOfflineDictionaries() {
    // After going to navigator global key and using it's context this approach stopped returning route from the dialog
    //  if (ModalRoute.of(currentContext)?.settings.name == dictionariesOnline) {
    //     Navigator.of(currentContext).pop();
    //   }
    Navigator.of(currentContext).popUntil((route) {
      if (route.settings.name == dictionariesOnline) return false;
      return true;
    });

    showDialog(
        context: currentContext,
        barrierColor: !kIsWeb ? Colors.transparent : Colors.black54,
        routeSettings: const RouteSettings(name: Routes.dictionariesOffline),
        builder: (BuildContext context) {
          return blurBackground(const SimpleDialog(
              alignment: Alignment.center,
              children: [Dictionaries(offline: true)]));
        });
  }

  static void showOnlineDictionaries() {
    // After goinf to navigator global key and using it's context this approach stopped returning route from the dialog
    // if (ModalRoute.of(currentContext)?.settings.name == dictionariesOffline) {
    //   Navigator.of(currentContext).pop();
    // }

    Navigator.of(currentContext).popUntil((route) {
      if (route.settings.name == dictionariesOffline) return false;
      return true;
    });

    showDialog(
        context: currentContext,
        barrierColor: !kIsWeb ? Colors.transparent : Colors.black54,
        routeSettings: const RouteSettings(name: Routes.dictionariesOnline),
        builder: (BuildContext context) {
          return blurBackground(const SimpleDialog(
              alignment: Alignment.center,
              children: [Dictionaries(offline: false)]));
        });
  }
}

BackdropFilter blurBackground(Widget child) {
  return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: child);
}

class StackObserver extends NavigatorObserver {
  final List<Route<dynamic>> _routeStack = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeStack.add(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeStack.removeLast();
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // This one actully remove first occurance not checking for previous route, which is OK for this app use cases, though doesn't cover all cases
    _routeStack.remove(route);
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    // routeStack.removeLast();
    // routeStack.add(newRoute);
    if (oldRoute != null && newRoute != null) {
      var i = _routeStack.indexOf(oldRoute);
      if (i > -1) {
        _routeStack[i] = newRoute;
      }
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

/// On Android back button will move pop the current route and if on home screen -> exit the app
class BackButtonHandler extends StatefulWidget {
  final Widget child;

  const BackButtonHandler({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  BackButtonHandlerState createState() => BackButtonHandlerState();
}

class BackButtonHandlerState extends State<BackButtonHandler> {
  bool tapped = false;
  bool get _isAndroid => Theme.of(context).platform == TargetPlatform.android;
  final waitForSecondBackPress = 2;

  @override
  Widget build(BuildContext context) {
    if (_isAndroid) {
      return WillPopScope(
        onWillPop: () async {
          if (Routes.currentRoute.settings.name != Routes.home) {
            Routes.goBack();
          }
          if (tapped) {
            return true;
          } else {
            tapped = true;
            Timer(
              Duration(
                seconds: waitForSecondBackPress,
              ),
              resetTimer,
            );

            showToast('Tap back again to quit'.i18n,
                context: context,
                animation: StyledToastAnimation.fade,
                reverseAnimation: StyledToastAnimation.fade);

            return false;
          }
        },
        child: widget.child,
      );
    } else {
      return widget.child;
    }
  }

  void resetTimer() {
    tapped = false;
  }
}
