import 'dart:async';
import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'user_repo.freezed.dart';
part 'user_repo.g.dart';

class UserRepo {
  static const _prefsKey = 'UserRepo';

  late UserState _state;
  final _out = StreamController<UserState>.broadcast();

  final SharedPreferences prefs;

  UserRepo({required this.prefs}) {
    final encoded = prefs.getString(_prefsKey);
    _state = encoded == null
        ? const UserState()
        : UserState.fromJson(jsonDecode(encoded));
  }

  void dispose() {
    _out.close();
  }

  UserState get state => _state;

  @visibleForTesting
  set state(UserState state) {
    _state = state;
    _out.add(state);
    prefs.setString(_prefsKey, jsonEncode(state.toJson()));
  }

  Stream<UserState> get stream => _out.stream;

  void login({required String userName}) {
    state = state.copyWith(
      status: AuthStatus.loggedIn,
      data: UserData(userName: userName),
    );
  }

  void logout() {
    state = state.copyWith(
      status: AuthStatus.loggedOut,
      data: null,
    );
  }
}

@freezed
class UserState with _$UserState {
  const factory UserState({
    @Default(AuthStatus.loggedOut) AuthStatus status,
    UserData? data,
  }) = _UserState;

  factory UserState.fromJson(Map<String, dynamic> json) =>
      _$UserStateFromJson(json);
}

enum AuthStatus {
  loggedOut,
  loggedIn,
}

@freezed
class UserData with _$UserData {
  const factory UserData({
    required String userName,
  }) = _UserData;

  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);
}
