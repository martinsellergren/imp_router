import 'dart:io';

import 'package:flutter/foundation.dart';

import '../page.dart';
import '../router.dart';

HistoryTransformer? get platformHistoryTransformer {
  if (kIsWeb) {
    return null;
  }
  if (Platform.isAndroid) {
    return uniquePageUpdatesHistoryTransformer;
  } else {
    return null;
  }
}

/// On android, say we have 3 tabs, A, B and C, and navigate e.g A->B->A->C,
/// then, normally (i.e with historyTransformer=null), back button will take you
/// revers direction e.g C->A->B->A->pop. But using this transformer and tapping
/// back button, instead it goes C->A->B->pop.
/// Note, pages without an uri can never be skipped.
List<List<ImpPage>> uniquePageUpdatesHistoryTransformer(
    List<List<ImpPage>> stackHistory) {
  if (stackHistory.isEmpty) return [];
  stackHistory = stackHistory
      .where((stack) => stack.length <= stackHistory.last.length)
      .toList();
  final topWidgetKey = stackHistory.last.last.widgetKey;
  final lastUpdates = stackHistory.reversed
      .takeWhile((stack) => stack.last.widgetKey == topWidgetKey);
  final rest = stackHistory.reversed
      .skipWhile((stack) => stack.last.widgetKey == topWidgetKey);
  final seenUris = <Uri>{};
  final pickedUpdates =
      lastUpdates.where((e) => e.last.uri == null || seenUris.add(e.last.uri!));
  final res = [
    ...rest.toList().reversed,
    ...pickedUpdates.toList().reversed,
  ];
  return res;
}

/// Back button will always pop; never revert page updates.
List<List<ImpPage>> noPageUpdatesHistoryTransformer(
    List<List<ImpPage>> stackHistory) {
  if (stackHistory.isEmpty) return [];
  stackHistory = stackHistory
      .where((stack) => stack.length <= stackHistory.last.length)
      .toList();
  final topWidgetKey = stackHistory.last.last.widgetKey;
  final lastUpdates = stackHistory.reversed
      .takeWhile((stack) => stack.last.widgetKey == topWidgetKey);
  final rest = stackHistory.reversed
      .skipWhile((stack) => stack.last.widgetKey == topWidgetKey);
  final pickedUpdate = lastUpdates.first;
  return [
    ...rest.toList().reversed,
    pickedUpdate,
  ];
}
