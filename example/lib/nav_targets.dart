import 'package:flutter/material.dart';

import 'pages/book_details_page.dart';
import 'pages/home/home_page.dart';
import 'pages/login_page.dart';
import 'pages/not_found_page.dart';
import 'pages/user_page.dart';

enum NavTargets {
  notFound,
  books,
  authors,
  misc,
  bookDetails,
  user,
  login;

  String get path => switch (this) {
        NavTargets.notFound => '/oups',
        NavTargets.books => '/books',
        NavTargets.authors => '/authors',
        NavTargets.misc => '/mics',
        NavTargets.bookDetails => '/book',
        NavTargets.user => '/user/details',
        NavTargets.login => '/login'
      };

  static NavTargets fromPage(Widget page) {
    return NavTargets.values.firstWhere(
        (e) => switch (e) {
              NavTargets.books => page is HomePage && page.tab == HomeTab.books,
              NavTargets.authors =>
                page is HomePage && page.tab == HomeTab.authors,
              NavTargets.misc => page is HomePage && page.tab == HomeTab.misc,
              NavTargets.bookDetails => page is BookDetailsPage,
              NavTargets.user => page is UserPage,
              NavTargets.notFound => page is NotFoundPage,
              NavTargets.login => page is LoginPage,
            },
        orElse: () => NavTargets.notFound);
  }

  static NavTargets fromUri(Uri uri) {
    if (uri.path == '/') return NavTargets.books;
    return NavTargets.values.firstWhere(
      (e) => uri.path == e.path,
      orElse: () => NavTargets.notFound,
    );
  }
}

/// Uri path must start with slash /, or else app will crash on web.
Uri? pageToUri(Widget page) {
  final destination = NavTargets.fromPage(page);
  return switch (destination) {
    NavTargets.notFound => Uri(path: destination.path),
    NavTargets.books => Uri(path: destination.path),
    NavTargets.authors => Uri(path: destination.path),
    NavTargets.misc => Uri(path: destination.path),
    NavTargets.bookDetails => Uri(
        path: destination.path,
        queryParameters: {
          'title': (page as BookDetailsPage).title,
        },
      ),
    NavTargets.user => Uri(path: destination.path),
    NavTargets.login => Uri(path: destination.path),
  };
}

Widget uriToPage(Uri uri) {
  // redirect / to /books
  // '/' has special meaning - it's the initial path that router receives when
  // there's no deep-link/ entered url going on.
  // In this case, '/' leads to HomePage, which sets url to /books, as above.
  if (uri.path == '/') {
    return const HomePage(tab: HomeTab.books);
  }
  final destination = NavTargets.fromUri(uri);
  return switch (destination) {
    NavTargets.notFound => const NotFoundPage(),
    NavTargets.books => const HomePage(tab: HomeTab.books),
    NavTargets.authors => const HomePage(tab: HomeTab.books),
    NavTargets.misc => const HomePage(tab: HomeTab.misc),
    NavTargets.bookDetails =>
      BookDetailsPage(title: uri.queryParameters['title']!),
    NavTargets.user => const UserPage(),
    NavTargets.login => const LoginPage(),
  };
}
