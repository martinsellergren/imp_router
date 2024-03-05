import 'package:flutter/material.dart';
import 'package:imp_router/imp_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError =
      presentFlutterErrorWithTruncatedRenderFlexOverflowMessage();
  usePathUrlStrategy();
  final prefs = await SharedPreferences.getInstance();
  runApp(App(prefs: prefs));
}
