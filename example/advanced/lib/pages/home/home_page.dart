import 'package:flutter/material.dart';
import 'package:imp_router/imp_router.dart';
import 'package:transitioned_indexed_stack/transitioned_indexed_stack.dart';

import '../../app.dart';
import '../user_page.dart';
import 'bodies/authors_body.dart';
import 'bodies/books_body.dart';
import 'bodies/misc_body.dart';

enum HomeTab {
  books,
  authors,
  misc,
}

class HomePage extends StatefulWidget {
  final HomeTab tab;

  const HomePage({super.key, this.tab = HomeTab.books});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _canPop = false;

  void _onPopPrevented(BuildContext context) {
    setState(() => _canPop = true);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(
          content: Text('Click again to exit'),
          duration: Duration(seconds: 1),
        ))
        .closed
        .then((value) {
      setState(() => _canPop = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.userState(select: (state) => state.data?.userName);
    return PopScope(
      canPop: _canPop,
      onPopInvoked: (didPop) {
        if (!didPop) _onPopPrevented(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Library of $userName'),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => context.impRouter.push(
                  const UserPage(),
                  transition: ContainerTransformPageTransitionsBuilder(
                      context: context),
                ),
              ),
            ),
          ],
        ),
        body: FadeIndexedStack(
          index: widget.tab.index,
          children: const [
            BooksBody(),
            AuthorsBody(),
            MiscBody(),
          ].map((e) => RepaintBoundary(child: e)).toList(),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.tab.index,
          onDestinationSelected: (i) {
            final newTab = HomeTab.values[i];
            if (newTab != widget.tab) {
              context.impRouter.updateCurrent(HomePage(tab: newTab));
            }
          },
          destinations: HomeTab.values
              .map(
                (e) => NavigationDestination(
                  icon: const Icon(Icons.info),
                  label: e.name,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
