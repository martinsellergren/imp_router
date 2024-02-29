import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'config.dart';
import 'page.dart';
import 'utils/history_transformers.dart';
import 'utils/utils.dart';

typedef HistoryTransformer = List<List<ImpPage>> Function(List<List<ImpPage>>);

class ImpRouter with ChangeNotifier {
  final _stackStreamController = StreamController<List<ImpPage>>.broadcast();

  int _stackBackPointer = 0;
  final List<ImpPage> _mountedPages = [];
  List<List<ImpPage>> _stackHistory = [];
  ImpPage? overlay;

  final PageToUri pageToUri;
  final UriToPage uriToPage;
  final int nKeepAlives;

  /// Applied after every push. Can tweak behavior of android back button.
  final HistoryTransformer? historyTransformer;

  ImpRouter({
    required this.pageToUri,
    required this.uriToPage,
    int? nKeepAlives,
    HistoryTransformer? historyTransformer,
  })  : nKeepAlives = kIsWeb ? (nKeepAlives ?? 10) : 0,
        historyTransformer =
            (historyTransformer ?? platformHistoryTransformer) {
    addListener(() {
      if (currentStack != null) {
        _stackStreamController.add(currentStack!);
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

  // public interface:

  Stream<List<ImpPage>> get stackStream =>
      _stackStreamController.stream.distinct();

  List<List<ImpPage>> get stackHistory => _stackHistory.toList();

  List<ImpPage>? get currentStack =>
      stackHistory.elementAtSafe(_stackHistory.length - 1 - _stackBackPointer);

  ImpPage? get top => currentStack?.lastOrNull;

  int get stackBackPointer => _stackBackPointer;

  List<ImpPage> get keepAlives {
    final seenWidgetKeys = <GlobalKey>{
      ...currentStack?.map((e) => e.widgetKey) ?? [],
      ..._mountedPages.map((e) => e.widgetKey),
    };
    return _stackHistory.reversed
        .expand((stack) => stack.reversed)
        .where((page) => seenWidgetKeys.add(page.widgetKey))
        .take(nKeepAlives)
        .toList();
  }

  void pushNewStack(List<ImpPage> newStack) {
    List.generate(_stackBackPointer, (index) => _stackHistory.removeLast());
    _stackBackPointer = 0;
    _stackHistory.add(newStack
        .map(
          (e) => e
            ..onWidgetMounting = _addMountedPage
            ..onWidgetUnmounting = _removeMountedPage,
        )
        .toList());
    if (historyTransformer != null) {
      _stackHistory = historyTransformer!(_stackHistory);
    }
    notifyListeners();
  }

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
