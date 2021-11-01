import 'package:flutter/material.dart';

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
    return _navigationKey.currentState!
        .pushNamed(routeName, arguments: arguments);
  }
}
