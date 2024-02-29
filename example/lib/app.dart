import 'dart:async';

import 'package:flutter/material.dart';
import 'package:imp_router/imp_router.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/user_repo.dart';
import 'pages/login_page.dart';
import 'url_mappings.dart';

class App extends StatefulWidget {
  final SharedPreferences prefs;

  const App({super.key, required this.prefs});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final _router = ImpRouter(
    pageToUri: pageToUri,
    uriToPage: uriToPage,
    nKeepAlives: 10,
  );
  late final _userRepo = UserRepo(prefs: widget.prefs);

  late final List<StreamSubscription> _subs;

  @override
  void initState() {
    super.initState();

    _router.addListener(() {
      // print('stackHistory: \n${_router.stackHistory.join('\n')}');
      // print('current: ${_router.currentStack}\n');
    });

    _subs = [
      _router.stackStream
          .cast<List<ImpPage>?>()
          .startWith(_router.currentStack)
          .whereNotNull()
          .listen((stack) => print('<me> stack: $stack')),
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
      child: MaterialApp.router(
        routerConfig: ImpRouterConfig(router: _router),
      ),
    );
  }
}

extension BuildContextScope on BuildContext {
  UserRepo get userRepo => read<UserRepo>();
  T userState<T>({T Function(UserState state)? select}) =>
      this.select<UserState, T>((value) => (select ?? ((v) => v as T))(value));
}
