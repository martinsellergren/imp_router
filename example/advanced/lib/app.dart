import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:imp_router/imp_router.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/user_repo.dart';
import 'pages/home/home_page.dart';
import 'pages/login_page.dart';
import 'router_mappings.dart';

class App extends StatefulWidget {
  final SharedPreferences prefs;

  const App({super.key, required this.prefs});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final _router = ImpRouter(
    initialPage: const HomePage(),
    pageToUri: pageToUri,
    uriToPage: uriToPage,
  );
  late final _userRepo = UserRepo(prefs: widget.prefs);

  late final List<StreamSubscription> _subs;

  @override
  void initState() {
    super.initState();
    _subs = [
      _router.stackStream
          .startWith(_router.stack)
          .where((e) => e.isNotEmpty)
          .listen((stack) =>
              log('stack: ${stack.map((e) => e.navTarget).toList()}')),
      _userRepo.stream
          .startWith(_userRepo.state)
          .map((state) => state.status == AuthStatus.loggedIn)
          .distinct()
          .listen((isLoggedIn) =>
              _router.setOverlay(isLoggedIn ? null : const LoginPage())),
    ];
  }

  @override
  void dispose() {
    _router.dispose();
    _userRepo.dispose();
    _subs.forEach((e) => e.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: _userRepo),
        StreamProvider.value(
            initialData: _userRepo.state, value: _userRepo.stream),
      ],
      child: ColoredBox(
        color: Colors.white,
        child: MaterialApp.router(
          routerConfig: ImpRouterConfig(router: _router),
        ),
      ),
    );
  }
}

extension BuildContextScope on BuildContext {
  UserRepo get userRepo => read<UserRepo>();
  T userState<T>({T Function(UserState state)? select}) =>
      this.select<UserState, T>((value) => (select ?? ((v) => v as T))(value));
}
