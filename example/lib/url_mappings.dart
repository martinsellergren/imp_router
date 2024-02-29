import 'package:flutter/material.dart';

import 'pages/book_details_page.dart';
import 'pages/home/home_page.dart';
import 'pages/not_found_page.dart';
import 'pages/user_page.dart';
import 'shared.dart';

Uri? pageToUri(Widget page) {
  switch (page) {
    case NotFoundPage _:
      return Uri(path: '/oups');
    case HomePage _:
      return switch (page.tab) {
        HomeTab.books => Uri(path: '/books'),
        HomeTab.authors => Uri(path: '/authors'),
        HomeTab.misc => Uri(path: '/misc'),
      };
    case BookDetailsPage _:
      return Uri(path: '/book', queryParameters: {
        'title': page.title,
      });
    case UserPage _:
      return Uri(path: '/user');
  }
  return null;
}

Widget uriToPage(Uri uri) {
  // redirect / to /books
  // '/' has special meaning - it's the initial path that router receives when
  // there's no deep-link/ entered url going on.
  // In this case, '/' leads to HomePage, which sets url to /books, as above.
  if (uri.path == '/') {
    return const HomePage(tab: HomeTab.books);
  }

  final lastSegment = uri.pathSegments.lastOrNull;
  return switch (lastSegment) {
    'books' => const HomePage(tab: HomeTab.books),
    'authors' => const HomePage(tab: HomeTab.authors),
    'writers' =>
      const HomePage(tab: HomeTab.authors), // redirect /writers to /authors
    'misc' => const HomePage(tab: HomeTab.misc),
    'book' => orNull(() => BookDetailsPage(
              title: uri.queryParameters['title']!,
            )) ??
        const NotFoundPage(),
    'user' => const UserPage(),
    _ => const NotFoundPage(),
  };
}
