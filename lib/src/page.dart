import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

// ignore: must_be_immutable
class ImpPage extends Page {
  /// This uri is set to whatever [ImpRouter.pageToUri] returns. If you push
  /// pages yourself through [ImpRouter.pushNewStack] you may also set it
  /// manually. It doesn't have much functional relevance. You may use it e.g as
  /// an id. Can be nice to have when you listen on the [stackStream] and want
  /// to evaluate the received stack of [ImpPage]s.
  ///
  /// This uri is however necessary for the [uniquePageUpdatesHistoryTransformer]
  /// to work properly.
  Uri? uri;

  final GlobalKey widgetKey;
  final Widget widget;
  final PageTransitionsBuilder? transition;
  final Duration transitionDuration;

  ImpPage({
    this.uri,
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

  @internal
  Function(ImpPage page)? onWidgetMounting;
  @internal
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
    return 'ImpPage(uri=$uri)'; // widget=${widget.runtimeType}, widgetKey=$widgetKey, hash=$hashCode)';
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

extension RouteImpPage on Route {
  ImpPage? get impPage => settings is ImpPage ? settings as ImpPage : null;
}
