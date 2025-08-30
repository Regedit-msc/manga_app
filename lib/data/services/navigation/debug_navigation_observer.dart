import 'package:flutter/material.dart';
import 'package:webcomic/data/services/debug/debug_logger.dart';

/// Custom route observer that logs navigation events in debug mode
class DebugNavigationObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);

    if (route is PageRoute) {
      DebugLogger.logNavigation(
        routeName: route.settings.name ?? 'Unknown Route',
        previousRoute: previousRoute?.settings.name,
        arguments: route.settings.arguments,
      );
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);

    if (newRoute is PageRoute) {
      DebugLogger.logNavigation(
        routeName: newRoute.settings.name ?? 'Unknown Route (Replace)',
        previousRoute: oldRoute?.settings.name,
        arguments: newRoute.settings.arguments,
      );
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);

    if (previousRoute is PageRoute) {
      DebugLogger.logNavigation(
        routeName: previousRoute.settings.name ?? 'Back to Previous',
        previousRoute: route.settings.name,
        arguments: previousRoute.settings.arguments,
      );
    }
  }
}
