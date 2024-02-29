import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart' as web;

extension IterableUtils<E> on Iterable<E> {
  E? elementAtSafe(int i) {
    return i < 0 ? null : elementAtOrNull(i);
  }
}

// Call in main before runApp to get rid of the # in the url.
void usePathUrlStrategy() {
  if (kIsWeb) {
    web.usePathUrlStrategy();
  }
}
