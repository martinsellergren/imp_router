import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'router.dart';
import 'utils/history_transformers.dart';

// ignore: must_be_immutable
class ImpPage extends Page {
  /// This uri is set to whatever [ImpRouter.pageToUri] returns. It doesn't have
  /// much functional relevance. You may use it e.g as an id. Can be nice to have
  /// when you listen on the [ImpRouter.stackStream] and want to evaluate the
  /// received stack of [ImpPage]s.
  ///
  /// On android, this uri is however necessary for the [uniquePageUpdatesHistoryTransformer]
  /// to work.
  Uri? uri;

  final GlobalKey widgetKey;
  final Widget widget;
  final PageTransitionsBuilder? transition;

  ImpPage({
    this.uri,
    GlobalKey? widgetKey,
    required this.widget,
    this.transition,
  })  : widgetKey = widgetKey ?? GlobalKey(),
        super(
          name: uri.toString(),
          key: UniqueKey(),
        );

  @internal
  Function(ImpPage page)? onWidgetMounting;
  @internal
  Function(ImpPage page)? onWidgetUnmounting;

  ImpRoute? createdRoute;

  @override
  String? get name => uri.toString();

  @override
  Route createRoute(BuildContext context) {
    final route = ImpRoute(
      builder: (context) => KeyedSubtree(
        key: widgetKey,
        child: widget,
      ),
      settings: this,
      transition: transition,
      onWidgetMounting: onWidgetMounting!,
      onWidgetUnmounting: onWidgetUnmounting!,
    );
    createdRoute = route;
    return route;
  }

  @override
  String toString() {
    return 'ImpPage(uri=$uri)'; // widget=${widget.runtimeType}, widgetKey=$widgetKey, hash=$hashCode)';
  }
}

class ImpRoute extends MaterialPageRoute {
  ImpRoute({
    required super.builder,
    required super.settings,
    required this.transition,
    required this.onWidgetMounting,
    required this.onWidgetUnmounting,
  });

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
    return transition != null
        ? transition!.buildTransitions(
            this, context, animation, secondaryAnimation, child)
        : Theme.of(context).pageTransitionsTheme.buildTransitions(
            this, context, animation, secondaryAnimation, child);
  }
}

extension RouteImpPage on Route {
  ImpPage? get impPage => settings is ImpPage ? settings as ImpPage : null;
}
