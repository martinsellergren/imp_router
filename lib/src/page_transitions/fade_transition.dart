import 'package:flutter/material.dart';

class FadePageTransition extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    final tween = animation.drive(CurveTween(curve: Curves.easeIn));
    return FadeTransition(
      opacity: tween,
      child: child,
    );
  }
}
