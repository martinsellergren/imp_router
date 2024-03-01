import 'package:flutter/material.dart';

import 'pages/book_details_page.dart';
import 'pages/home/home_page.dart';
import 'pages/login_page.dart';
import 'pages/not_found_page.dart';
import 'pages/user_page.dart';

enum NavTarget {
  notFound,
  books,
  authors,
  misc,
  bookDetails,
  user,
  login;

  String get path => switch (this) {
        NavTarget.notFound => '/oups',
        NavTarget.books => '/books',
        NavTarget.authors => '/authors',
        NavTarget.misc => '/mics',
        NavTarget.bookDetails => '/book',
        NavTarget.user => '/user/details',
        NavTarget.login => '/login'
      };

  static NavTarget fromPage(Widget page) {
    return NavTarget.values.firstWhere(
        (e) => switch (e) {
              NavTarget.books => page is HomePage && page.tab == HomeTab.books,
              NavTarget.authors =>
                page is HomePage && page.tab == HomeTab.authors,
              NavTarget.misc => page is HomePage && page.tab == HomeTab.misc,
              NavTarget.bookDetails => page is BookDetailsPage,
              NavTarget.user => page is UserPage,
              NavTarget.notFound => page is NotFoundPage,
              NavTarget.login => page is LoginPage,
            },
        orElse: () => NavTarget.notFound);
  }

  static NavTarget fromUri(Uri uri) {
    return NavTarget.values.firstWhere(
      (e) => uri.path == e.path,
      orElse: () => NavTarget.notFound,
    );
  }
}

/// Uri path must start with slash /, or else app will crash on web.
Uri? pageToUri(Widget page) {
  final destination = NavTarget.fromPage(page);
  return switch (destination) {
    NavTarget.notFound => Uri(path: destination.path),
    NavTarget.books => Uri(path: destination.path),
    NavTarget.authors => Uri(path: destination.path),
    NavTarget.misc => Uri(path: destination.path),
    NavTarget.bookDetails => Uri(
        path: destination.path,
        queryParameters: {
          'title': (page as BookDetailsPage).title,
        },
      ),
    NavTarget.user => Uri(path: destination.path),
    NavTarget.login => Uri(path: destination.path),
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
  final destination = NavTarget.fromUri(uri);
  return switch (destination) {
    NavTarget.notFound => const NotFoundPage(),
    NavTarget.books => const HomePage(tab: HomeTab.books),
    NavTarget.authors => const HomePage(tab: HomeTab.books),
    NavTarget.misc => const HomePage(tab: HomeTab.misc),
    NavTarget.bookDetails =>
      BookDetailsPage(title: uri.queryParameters['title']!),
    NavTarget.user => const UserPage(),
    NavTarget.login => const LoginPage(),
  };
}
