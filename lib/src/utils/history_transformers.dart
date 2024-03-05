import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../page.dart';
import '../router.dart';

HistoryTransformer get platformDefaultHistoryTransformer {
  if (kIsWeb) {
    return chronologicalHistoryTransformer;
  } else if (Platform.isAndroid) {
    return (currentStackHistory) => uniquePageUpdatesHistoryTransformer(
        noBackingDownHistoryTransformer(currentStackHistory));
  } else {
    return straightUpwardsHistoryTransformer;
  }
}

/// Back button takes you back chronologically, i.e it can push back previous screen.
/// This is what happens without filtering.
/// When a popped screen it pushed back its previous state is preserved if [ImpRouter.nKeepAlives]
/// is > 0.
List<List<ImpPage>> chronologicalHistoryTransformer(
    List<List<ImpPage>> stackHistory) {
  return stackHistory;
}

/// Going back in history never takes you back to deeper content.
/// I.e back button can't push back a screen, but can revert page updates.
List<List<ImpPage>> noBackingDownHistoryTransformer(
    List<List<ImpPage>> stackHistory) {
  if (stackHistory.isEmpty) return [];
  final top = stackHistory.last.last;
  final below = stackHistory.last.reversed.elementAtOrNull(1);
  return [
    ...stackHistory.reversed
        .skip(1)
        .skipWhile(
            (e) => !(e.last.widgetKey == top.widgetKey || e.last == below))
        .skipWhile((e) => e.last == top)
        .toList()
        .reversed,
    stackHistory.last,
  ];
}

/// Same as [noBackingDownHistoryTransformer] but history only holds unique page
/// updates - older ones are discarded.
///
/// Say we have 3 tabs, A, B and C, and navigate e.g A->B->A->C with
/// [ImpRouter.updateCurrent], then, normally
/// (i.e [chronologicalHistoryTransformer] / [noBackingDownHistoryTransformer]),
/// back button will take you revers direction e.g C->A->B->A->pop. But using
/// this transformer it will instead it go C->A->B->pop.
///
/// IMPORTANT: Page updates without an uri can never be discarded. See
/// [ImpPage.uri].
List<List<ImpPage>> uniquePageUpdatesHistoryTransformer(
    List<List<ImpPage>> stackHistory) {
  if (stackHistory.isEmpty) return [];
  stackHistory = noBackingDownHistoryTransformer(stackHistory);
  final topWidgetKey = stackHistory.last.last.widgetKey;
  final lastUpdates = stackHistory.reversed
      .takeWhile((stack) => stack.last.widgetKey == topWidgetKey);
  final rest = stackHistory.reversed
      .skipWhile((stack) => stack.last.widgetKey == topWidgetKey);
  final seenUris = <Uri>{};
  final pickedUpdates =
      lastUpdates.where((e) => e.last.uri == null || seenUris.add(e.last.uri!));
  return [
    ...rest.toList().reversed,
    ...pickedUpdates.toList().reversed,
  ];
}

/// Back button will always pop; never push pages back or revert page updates.
List<List<ImpPage>> straightUpwardsHistoryTransformer(
    List<List<ImpPage>> stackHistory) {
  final seen = <int>{};
  addIfSmaller(int n) => seen.isEmpty || n < seen.max ? seen.add(n) : false;
  final res = stackHistory.reversed
      .where((e) => addIfSmaller(e.length))
      .toList()
      .reversed
      .toList();
  return res;
}
