import 'package:flutter/material.dart';

class FadePageRouteBuilder<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;
  final RouteSettings settings;

  FadePageRouteBuilder({
    required this.builder,
    required this.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
                parent: animation,
                curve: Curves.easeIn,
                reverseCurve: Curves.easeOut);
            Animation<double> newOpacityAnimation =
                Tween(begin: 0.0, end: 1.0).animate(curvedAnimation);
            return FadeTransition(
              opacity: newOpacityAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 100),
          settings: settings,
        );
}
