import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

import 'config.dart';
import 'page.dart';
import 'page_transitions/container_transform_transition.dart';
import 'utils/history_transformers.dart';
import 'utils/utils.dart';

typedef HistoryTransformer = List<List<ImpPage>> Function(
    List<List<ImpPage>> currentStackHistory);

/// An imperative router.
class ImpRouter with ChangeNotifier {
  /// This mapper is used to connect a page (some widget) to an uri. This is
  /// good for two things:
  /// 1) On web, mapped uri appears in address bar, which also enables navigation
  ///    with browser back/forward buttons.
  /// 2) The uri is attached to corresponding ImpPage, see [ImpPage.uri].
  ///
  /// [pageToUri]=null is same as return uri=null for every mapping.
  /// Leaving this as null is perfectly valid if you don't need this feature.
  final PageToUri? pageToUri;

  /// This mapper is used when the app receives a new url to decide which page
  /// to show. A web app typically receives a new url when you manually enter an
  /// url in the address bar or when you refresh the page. A non-web may receive
  /// an url through [deep linking](https://docs.flutter.dev/ui/navigation/deep-linking).
  ///
  /// If this is null, app will default to initialPage whenever it receives a new url.
  /// Leaving this as null is perfectly valid if you don't need this feature.
  final UriToPage? uriToPage;

  /// Shown initially, and whenever the app receives the url '/'.
  final Widget initialPage;

  /// History transformation applied after every push. Can e.g tweak behavior of
  /// android back button. Make sure web uses [chronologicalHistoryTransformer]
  /// (the default) - otherwise browser nav button navigation will not work well.
  final HistoryTransformer historyTransformer;

  /// Number of pages to preserve state of.
  /// Only relevant when [historyTransformer] = [chronologicalHistoryTransformer].
  final int nKeepAlives;

  /// Throttle time for navigation events.
  ///
  /// Ignore events which are too close in time. This might happen for example if
  /// there is some extra trash click when you tried to just click a button onces.
  /// Goes like this:
  /// - Event 1, received and processed.
  /// - Event 2 received in less than throttleDuration after event 1 - and so is ignored.
  /// - Event 3 received in more than throttleDuration after event 1 - and so is processed.
  final Duration throttleDuration;

  final _stackStreamController = StreamController<List<ImpPage>>.broadcast();
  late final _in = StreamController<Function>()
    ..stream.throttleTime(throttleDuration).map((f) => f()).listen(null);

  int _stackBackPointer = 0;
  final List<ImpPage> _mountedPages = [];
  @internal
  List<List<ImpPage>> stackHistory = [];
  ImpPage? overlay;

  ImpRouter({
    this.pageToUri,
    this.uriToPage,
    required this.initialPage,
    HistoryTransformer? historyTransformer,
    int? nKeepAlives,
    this.throttleDuration = const Duration(milliseconds: 50),
  })  : nKeepAlives = nKeepAlives ?? (kIsWeb ? 10 : 0),
        historyTransformer =
            (historyTransformer ?? platformDefaultHistoryTransformer) {
    addListener(() {
      if (stack.isNotEmpty) {
        _stackStreamController.add(stack);
      }
    });
  }

  @override
  void dispose() {
    _stackStreamController.close();
    _in.close();
    super.dispose();
  }

  void _addMountedPage(ImpPage page) {
    _mountedPages.add(page);
    notifyListeners();
  }

  void _removeMountedPage(ImpPage page) {
    _mountedPages.remove(page);
    notifyListeners();
  }

  @internal
  void setStackBackPointer(int p) {
    _stackBackPointer = p;
    notifyListeners();
  }

  // Does not include overlay.
  @internal
  List<ImpPage>? get currentStack =>
      stackHistory.elementAtSafe(stackHistory.length - 1 - _stackBackPointer);

  @internal
  void popRoute(Route route) {
    final newStack = currentStack?.toList() ?? [];
    newStack.removeWhere((e) => e == route.impPage);
    pushNewStack(newStack);
  }

  // public interface:

  /// Empty only before router has shown first page.
  List<ImpPage> get stack => [
        ...currentStack ?? [],
        if (overlay != null) overlay!,
      ];

  /// Null only before router has shown first page.
  ImpPage? get top => stack.lastOrNull;

  /// For listening on navigation changes.
  Stream<List<ImpPage>> get stackStream =>
      _stackStreamController.stream.distinct(listEquals);

  int get stackBackPointer => _stackBackPointer;

  List<ImpPage> get keepAlives {
    final seenWidgetKeys = <GlobalKey>{
      ...currentStack?.map((e) => e.widgetKey) ?? [],
      ..._mountedPages.map((e) => e.widgetKey),
    };
    return stackHistory.reversed
        .expand((stack) => stack.reversed)
        .where((page) => seenWidgetKeys.add(page.widgetKey))
        .take(nKeepAlives)
        .toList();
  }

  /// Use this to replace the whole stack with [newStack].
  ///
  /// If you aim for a page update, like [updateCurrent], the new ImpPage
  /// should have same widgetKey and transition as replaced page.
  ///
  /// Set [disableThrottling] to true to make sure this update happens, even
  /// when calls are very close in time (within [throttleDuration]).
  void pushNewStack(List<ImpPage> newStack, {bool disableThrottling = false}) {
    void f() {
      if (newStack.isEmpty) {
        debugPrint('imp_router: Attempted to pop last route. Not allowed.');
        return;
      }
      List.generate(_stackBackPointer, (index) => stackHistory.removeLast());
      _stackBackPointer = 0;
      stackHistory.add(newStack
          .map(
            (e) => e
              ..uri ??= pageToUri?.call(e.widget)
              ..onWidgetMounting = _addMountedPage
              ..onWidgetUnmounting = _removeMountedPage,
          )
          .toList());
      stackHistory = historyTransformer(stackHistory);
      notifyListeners();
    }

    stack.isEmpty || disableThrottling ? f() : _in.add(f);
  }

  /// Push a new [page] to the top of the stack.
  ///
  /// If [replace] is true, current top is popped before pushing new page.
  ///
  /// [transition] is compatible with e.g https://pub.dev/packages/animations
  /// as well as flutter's default PageTransitionsBuilder implementations, like
  /// [FadeUpwardsPageTransitionsBuilder], [OpenUpwardsPageTransitionsBuilder],
  /// [ZoomPageTransitionsBuilder] and [CupertinoPageTransitionsBuilder]. Also
  /// checkout [ContainerTransformPageTransition].
  /// For iOS back swipe to work, [CupertinoPageTransitionsBuilder] is the way
  /// to go. When no [transition] is provided, it defaults to
  /// [ThemeData.pageTransitionsTheme].
  void push(
    Widget page, {
    bool replace = false,
    PageTransitionsBuilder? transition,
    Duration? transitionDuration,
    bool disableThrottling = false,
  }) {
    final newStack = currentStack?.toList() ?? [];
    if (replace && newStack.isNotEmpty) newStack.removeLast();
    newStack.add(
      ImpPage(
        widget: page,
        transition: transition,
        transitionDuration: transitionDuration,
      ),
    );
    pushNewStack(newStack, disableThrottling: disableThrottling);
  }

  /// Pop current page. Throws if there's only 1 page on the stack currently
  /// (unless [fallback] is set).
  void pop({Widget? fallback, bool disableThrottling = false}) {
    final newStack = currentStack?.toList() ?? [];
    if (newStack.isNotEmpty) newStack.removeLast();
    if (newStack.isEmpty && fallback != null) {
      newStack.add(
        ImpPage(
          widget: fallback,
          transition: const FadeThroughPageTransitionsBuilder(),
        ),
      );
    }
    pushNewStack(newStack, disableThrottling: disableThrottling);
  }

  /// Update current page with new parameters.
  /// [page] must be of same type as current page.
  /// This will trigger e.g didUpdateWidget if [page] is a stateful widget.
  void updateCurrent(Widget page, {bool disableThrottling = false}) {
    assert(page.runtimeType == top?.widget.runtimeType);
    final newStack = currentStack?.toList();
    if (newStack == null) return;
    ImpPage replaced = newStack.removeLast();
    newStack.add(
      ImpPage(
        widget: page,
        transition: replaced.transition,
        widgetKey: replaced.widgetKey,
      ),
    );
    pushNewStack(newStack, disableThrottling: disableThrottling);
  }

  /// Set an overlay page above everything else.
  /// Difference between this and [push] is that this page can't be navigated away
  /// from using e.g android back button or browser buttons.
  ///
  /// Set it to null to remove it.
  ///
  /// Note on web: If you want this overlay page to affect the address bar,
  /// simply add it to [pageToUri] as any other page. IMPORTANT though: in
  /// [uriToPage] make sure you DO NOT link the url to this page, as that would
  /// mean, when opening that particular url, user is taken to the overlay page,
  /// plus showing it through this [setOverlay], so two of them would appear on
  /// top of each other. Instead, in [uriToPage], link that url to e.g your home page.
  void setOverlay(
    Widget? overlay, {
    PageTransitionsBuilder? transition,
  }) {
    this.overlay = overlay == null
        ? null
        : (ImpPage(
            widget: overlay,
            transition: transition ?? const FadeThroughPageTransitionsBuilder(),
          )
          ..uri ??= pageToUri?.call(overlay)
          ..onWidgetMounting = (_) {}
          ..onWidgetUnmounting = (_) {});
    notifyListeners();
  }
}
