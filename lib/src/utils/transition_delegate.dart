import 'package:flutter/material.dart';

import '../page.dart';

class ImpTransitionDelegate extends TransitionDelegate<void> {
  @override
  Iterable<RouteTransitionRecord> resolve(
      {required List<RouteTransitionRecord> newPageRouteHistory,
      required Map<RouteTransitionRecord?, RouteTransitionRecord>
          locationToExitingPageRoute,
      required Map<RouteTransitionRecord?, List<RouteTransitionRecord>>
          pageRouteToPagelessRoutes}) {
    final List<RouteTransitionRecord> res = [];
    for (final e in newPageRouteHistory) {
      if (e.isWaitingForEnteringDecision) {
        e.isAnUpdate(locationToExitingPageRoute.values.toList())
            ? e.markForAdd()
            : e.markForPush();
      }
      res.add(e);
    }
    for (final entry in locationToExitingPageRoute.entries) {
      final e = entry.value;
      if (e.isWaitingForExitingDecision) {
        e.isAnUpdate(newPageRouteHistory) ? e.markForRemove() : e.markForPop();
        pageRouteToPagelessRoutes[e]?.forEach((e) => e.markForPop());
      }
      res.add(e);
    }
    return res;
  }
}

extension on RouteTransitionRecord {
  bool isAnUpdate(List<RouteTransitionRecord> newPageRouteHistory) {
    final page = route.impPage;
    if (page == null) return false;
    final res = newPageRouteHistory.any((e) {
      final p = e.route.impPage;
      if (p == null) return false;
      return page.widgetKey == p.widgetKey && page.key != p.key;
    });
    return res;
  }
}

class NoAnimationTransitionDelegate extends TransitionDelegate<void> {
  @override
  Iterable<RouteTransitionRecord> resolve({
    required List<RouteTransitionRecord> newPageRouteHistory,
    required Map<RouteTransitionRecord?, RouteTransitionRecord>
        locationToExitingPageRoute,
    required Map<RouteTransitionRecord?, List<RouteTransitionRecord>>
        pageRouteToPagelessRoutes,
  }) {
    final List<RouteTransitionRecord> results = <RouteTransitionRecord>[];

    for (final RouteTransitionRecord pageRoute in newPageRouteHistory) {
      if (pageRoute.isWaitingForEnteringDecision) {
        pageRoute.markForAdd();
      }
      results.add(pageRoute);
    }
    for (final RouteTransitionRecord exitingPageRoute
        in locationToExitingPageRoute.values) {
      if (exitingPageRoute.isWaitingForExitingDecision) {
        exitingPageRoute.markForRemove();
        final List<RouteTransitionRecord>? pagelessRoutes =
            pageRouteToPagelessRoutes[exitingPageRoute];
        if (pagelessRoutes != null) {
          for (final RouteTransitionRecord pagelessRoute in pagelessRoutes) {
            pagelessRoute.markForRemove();
          }
        }
      }
      results.add(exitingPageRoute);
    }
    return results;
  }
}
