import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'config.dart';
import 'page.dart';
import 'utils/history_transformers.dart';
import 'utils/utils.dart';

typedef HistoryTransformer = List<List<ImpPage>> Function(List<List<ImpPage>>);

class ImpRouter with ChangeNotifier {
  final _stackStreamController = StreamController<List<ImpPage>>.broadcast();

  int _stackBackPointer = 0;
  final List<ImpPage> _mountedPages = [];
  @internal
  List<List<ImpPage>> stackHistory = [];
  ImpPage? overlay;

  final PageToUri pageToUri;
  final UriToPage uriToPage;

  /// Shown initially, and whenever user navigates to / in a browser.
  final Widget initialPage;

  final int nKeepAlives;

  /// Applied after every push. Can tweak behavior of android back button.
  final HistoryTransformer? historyTransformer;

  ImpRouter({
    required this.pageToUri,
    required this.uriToPage,
    required this.initialPage,
    int? nKeepAlives,
    HistoryTransformer? historyTransformer,
  })  : nKeepAlives = kIsWeb ? (nKeepAlives ?? 10) : 0,
        historyTransformer =
            (historyTransformer ?? platformHistoryTransformer) {
    addListener(() {
      if (stack.isNotEmpty) {
        _stackStreamController.add(stack);
      }
    });
  }

  @override
  void dispose() {
    _stackStreamController.close();
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

  // Does not include overlay.
  @internal
  List<ImpPage>? get currentStack =>
      stackHistory.elementAtSafe(stackHistory.length - 1 - _stackBackPointer);

  // public interface:

  /// Empty only before router has shown first page.
  List<ImpPage> get stack => [
        ...currentStack ?? [],
        if (overlay != null) overlay!,
      ];

  /// Null only before router has shown first page.
  ImpPage? get top => stack.lastOrNull;

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

  void pushNewStack(List<ImpPage> newStack) {
    List.generate(_stackBackPointer, (index) => stackHistory.removeLast());
    _stackBackPointer = 0;
    stackHistory.add(newStack
        .map(
          (e) => e
            ..onWidgetMounting = _addMountedPage
            ..onWidgetUnmounting = _removeMountedPage,
        )
        .toList());
    if (historyTransformer != null) {
      stackHistory = historyTransformer!(stackHistory);
    }
    notifyListeners();
  }

  /// [transition] is compatible with e.g https://pub.dev/packages/animations
  void push(
    Widget page, {
    bool replace = false,
    PageTransitionsBuilder? transition,
    Duration transitionDuration = const Duration(milliseconds: 300),
  }) {
    final newStack = currentStack?.toList() ?? [];
    if (replace && newStack.isNotEmpty) newStack.removeLast();
    newStack.add(
      ImpPage(
        uri: pageToUri(page),
        widget: page,
        transition: transition ??
            (replace
                ? const FadeThroughPageTransitionsBuilder()
                : const SharedAxisPageTransitionsBuilder(
                    transitionType: SharedAxisTransitionType.horizontal,
                  )),
        transitionDuration: transitionDuration,
      ),
    );
    pushNewStack(newStack);
  }

  void pop({Widget? fallback}) {
    final newStack = currentStack?.toList() ?? [];
    if (newStack.isNotEmpty) newStack.removeLast();
    if (newStack.isEmpty && fallback != null) {
      newStack.add(
        ImpPage(
          uri: pageToUri(fallback),
          widget: fallback,
          transition: const FadeThroughPageTransitionsBuilder(),
        ),
      );
    }
    pushNewStack(newStack);
  }

  void updateCurrent(Widget page) {
    assert(page.runtimeType == top?.widget.runtimeType);
    final newStack = currentStack?.toList();
    if (newStack == null) return;
    ImpPage replaced = newStack.removeLast();
    newStack.add(
      ImpPage(
        uri: pageToUri(page),
        widget: page,
        transition: replaced.transition,
        widgetKey: replaced.widgetKey,
      ),
    );
    pushNewStack(newStack);
  }

  void setStackBackPointer(int p) {
    _stackBackPointer = p;
    notifyListeners();
  }

  void setOverlay(
    Widget? overlay, {
    PageTransitionsBuilder? transition,
    Duration transitionDuration = const Duration(milliseconds: 300),
  }) {
    this.overlay = overlay == null
        ? null
        : (ImpPage(
            uri: pageToUri(overlay),
            widget: overlay,
            transition: transition,
            transitionDuration: transitionDuration,
          )
          ..onWidgetMounting = (_) {}
          ..onWidgetUnmounting = (_) {});
    notifyListeners();
  }
}
