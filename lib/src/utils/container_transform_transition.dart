import 'package:flutter/material.dart';

// Container transform that mimic material3's OpenContainer.
class ContainerTransformPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Must be a context of same size as the trigger button.
  /// Normally just wrap he button in a Builder and the context will be good.
  final BuildContext context;

  ContainerTransformPageTransitionsBuilder({required this.context});

  late final _tween = _createTween(context);

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final rectAnimation =
        _tween.chain(CurveTween(curve: Curves.ease)).animate(animation);
    return Stack(
      children: [
        PositionedTransition(rect: rectAnimation, child: child),
      ],
    );
  }
}

Tween<RelativeRect> _createTween(BuildContext context) {
  final windowSize = MediaQuery.of(context).size;
  final box = context.findRenderObject() as RenderBox;
  final rect = box.localToGlobal(Offset.zero) & box.size;
  final relativeRect = RelativeRect.fromSize(rect, windowSize);
  return RelativeRectTween(
    begin: relativeRect,
    end: RelativeRect.fill,
  );
}

/// The ContainerTransformPageTransitionsBuilder often triggers a 'RenderFlex
/// overflowed' assertion. This is expected and harmless, just quite impossible
/// to disable (see https://github.com/flutter/flutter/issues/100789), except
/// doing it the forceful way:
/// in main,
/// FlutterError.onError = presentFlutterErrorWithTruncatedRenderFlexOverflowMessage();
///
/// Result is, instead of cluttered logs in debug mode, there's just 1 line
/// debugPrint, e.g 'A RenderFlex overflowed by 21 pixels on the bottom.'
Function(FlutterErrorDetails details)
    presentFlutterErrorWithTruncatedRenderFlexOverflowMessage({
  Function(FlutterErrorDetails details)? furtherHandling,
}) {
  return (details) {
    details.toString().contains('A RenderFlex overflowed')
        ? debugPrint(details.exception.toString())
        : furtherHandling?.call(details) ?? FlutterError.presentError(details);
  };
}
