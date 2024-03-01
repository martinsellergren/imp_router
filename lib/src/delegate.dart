import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import 'config.dart';
import 'page.dart';
import 'router.dart';
import 'utils/transition_delegate.dart';
import 'utils/utils.dart';

class ImpDelegate extends RouterDelegate<ImpRouteInformation>
    with ChangeNotifier {
  final ImpRouter router;

  ImpDelegate({required this.router}) {
    router.addListener(notifyListeners);
    Provider.debugCheckInvalidValueType = null;
  }

  @override
  Future<void> setInitialRoutePath(ImpRouteInformation configuration) {
    if (configuration.uri.path == '/') {
      router.push(router.initialPage);
      return SynchronousFuture(null);
    } else {
      return setNewRoutePath(configuration);
    }
  }

  @override
  Future<void> setNewRoutePath(ImpRouteInformation configuration) {
    final newUri = configuration.uri;
    final newPageHash = configuration.pageHash;
    if (router.top.hashCode == newPageHash) {
      return SynchronousFuture(null);
    }
    final backPointer = router.stackHistory.reversed
        .map((e) => e.last.hashCode)
        .indexed
        .firstWhereOrNull((e) => e.$2 == newPageHash)
        ?.$1;
    if (backPointer != null && newPageHash != null) {
      router.setStackBackPointer(backPointer);
    } else if (newUri != router.top?.uri) {
      final widget =
          router.uriToPage?.call(configuration.uri) ?? router.initialPage;
      router.pushNewStack([ImpPage(widget: widget)]);
    }
    return SynchronousFuture(null);
  }

  @override
  ImpRouteInformation? get currentConfiguration {
    final top = router.top?.widget;
    final uri = top == null ? null : router.pageToUri?.call(top);
    return uri == null
        ? null
        : ImpRouteInformation(uri: uri, pageHash: router.top.hashCode);
  }

  @override
  Future<bool> popRoute() {
    final currentStack = router.currentStack;
    if (currentStack == null) return SynchronousFuture(false);
    if (router.overlay != null) return SynchronousFuture(false);
    final prevStack =
        router.stackHistory.reversed.elementAtSafe(router.stackBackPointer + 1);
    final prevTop = prevStack?.last;
    if (prevTop != null) {
      router.setStackBackPointer(router.stackBackPointer + 1);
    } else if (currentStack.length <= 1) {
      return SynchronousFuture(false);
    } else {
      router.setStackBackPointer(router.stackBackPointer + 1);
    }
    return SynchronousFuture(true);
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: router,
      child: _ForcePushUriOnPushingSamePage(
        router: router,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (router.keepAlives.isNotEmpty)
              Visibility(
                visible: false,
                maintainState: true,
                child: _KeepAlives(router: router),
              ),
            _Navigator(router: router),
          ],
        ),
      ),
    );
  }
}

extension BuildContextRouter on BuildContext {
  ImpRouter get impRouter => read<ImpRouter>();
}

class _ForcePushUriOnPushingSamePage extends StatefulWidget {
  final ImpRouter router;
  final Widget child;

  const _ForcePushUriOnPushingSamePage(
      {required this.router, required this.child});

  @override
  State<_ForcePushUriOnPushingSamePage> createState() =>
      _ForcePushUriOnPushingSamePageState();
}

class _ForcePushUriOnPushingSamePageState
    extends State<_ForcePushUriOnPushingSamePage> {
  late final StreamSubscription _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.router.stackStream
        .map((event) => event.last)
        .distinct()
        .pairwise()
        .listen((event) {
      final prev = event.first;
      final current = event.last;
      if (prev.uri != null &&
          prev.uri == current.uri &&
          widget.router.stackBackPointer == 0) {
        Router.navigate(context, () {});
      }
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _KeepAlives extends StatelessWidget {
  final ImpRouter router;

  const _KeepAlives({required this.router});

  @override
  Widget build(BuildContext context) {
    return Overlay.wrap(
      child: Stack(
        children: [
          ...router.keepAlives.map(
            (e) => KeyedSubtree(
              key: e.widgetKey,
              child: e.widget,
            ),
          ),
        ],
      ),
    );
  }
}

class _Navigator extends StatelessWidget {
  final ImpRouter router;

  const _Navigator({required this.router});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      pages: [...router.stack],
      transitionDelegate: ImpTransitionDelegate(),
      onPopPage: (route, result) {
        router.pop();
        return route.didPop(result);
      },
    );
  }
}
