import 'package:flutter/material.dart';

// ignore: must_be_immutable
class ImpPage extends Page {
  ImpPage({
    required this.uri,
    GlobalKey? widgetKey,
    required this.widget,
    this.transition,
    Duration? transitionDuration,
  })  : widgetKey = widgetKey ?? GlobalKey(),
        transitionDuration = transition == null
            ? Duration.zero
            : const Duration(milliseconds: 300),
        super(
          name: uri.toString(),
          key: UniqueKey(),
        );

  final Uri? uri;
  final GlobalKey widgetKey;
  final Widget widget;
  final PageTransitionsBuilder? transition;
  final Duration transitionDuration;

  Function(ImpPage page)? onWidgetMounting;
  Function(ImpPage page)? onWidgetUnmounting;

  @override
  Route createRoute(BuildContext context) {
    return ImpRoute(
      pageBuilder: (_, __, ___) => KeyedSubtree(
        key: widgetKey,
        child: widget,
      ),
      settings: this,
      transition: transition,
      transitionDuration: transitionDuration,
      onWidgetMounting: onWidgetMounting!,
      onWidgetUnmounting: onWidgetUnmounting!,
    );
  }

  @override
  String toString() {
    return 'ImpPage(uri=$uri widget=${widget.runtimeType}, widgetKey=$widgetKey, hash=$hashCode)';
  }
}

class ImpRoute extends PageRouteBuilder {
  ImpRoute({
    required super.pageBuilder,
    required super.settings,
    required this.transition,
    required super.transitionDuration,
    required this.onWidgetMounting,
    required this.onWidgetUnmounting,
  }) : super(reverseTransitionDuration: transitionDuration);

  final PageTransitionsBuilder? transition;

  final Function(ImpPage page) onWidgetMounting;
  final Function(ImpPage page) onWidgetUnmounting;
  bool _didCallWidgetUnmounting = false;

  @override
  void install() {
    super.install();
    Future(() => onWidgetMounting(settings as ImpPage));
  }

  @override
  void dispose() {
    if (!_didCallWidgetUnmounting) {
      // Fallback for case when route is markForRemove in the TransitionDelegate.
      onWidgetUnmounting(settings as ImpPage);
    }
    super.dispose();
  }

  @override
  AnimationController createAnimationController() {
    return AnimationController(
      duration: transitionDuration,
      reverseDuration: reverseTransitionDuration,
      vsync: navigator!,
    )..addStatusListener((status) {
        if (status == AnimationStatus.dismissed) {
          onWidgetUnmounting(settings as ImpPage);
          _didCallWidgetUnmounting = true;
        }
      });
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return transition == null
        ? child
        : transition!.buildTransitions(
            this, context, animation, secondaryAnimation, child);
  }
}

extension RouteSettingsImpPage on RouteSettings {
  ImpPage? get impPage => this is ImpPage ? this as ImpPage : null;
}
