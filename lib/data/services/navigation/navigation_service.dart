import 'package:flutter/material.dart';
import 'package:webcomic/data/services/debug/debug_logger.dart';

abstract class NavigationService {
  Future<dynamic> navigateTo(String routeName, {dynamic arguments});
}

class NavigationServiceImpl extends NavigationService {
  GlobalKey<NavigatorState> _navigationKey = GlobalKey<NavigatorState>();

  GlobalKey<NavigatorState> get navigationKey => _navigationKey;

  void pop() {
    return _navigationKey.currentState!.pop();
  }

  Future<dynamic> navigateTo(String routeName, {dynamic arguments}) {
    // Log navigation attempt
    DebugLogger.logNavigation(
      routeName: routeName,
      arguments: arguments,
    );

    return _navigationKey.currentState!
        .pushNamed(routeName, arguments: arguments);
  }
}
