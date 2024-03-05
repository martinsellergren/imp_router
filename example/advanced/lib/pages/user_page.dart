import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:imp_router/imp_router.dart';

import '../app.dart';
import '../my_back_button.dart';
import 'home/home_page.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userData = context.userState();
    final userName = context.userState(select: (state) => state.data?.userName);
    return Scaffold(
      appBar: AppBar(
        leading: const MyBackButton(),
        title: Text('User page for $userName'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => context.impRouter.push(
                const UserPage(),
              ),
              child: const Text('Push another on top'),
            ),
            TextButton(
              onPressed: () => context.impRouter.push(
                const UserPage(),
                replace: true,
              ),
              child: const Text('Push another and replace top'),
            ),
            TextButton(
              onPressed: () {
                final router = context.impRouter;
                router.pushNewStack([
                  router.stack.first.widget is HomePage
                      ? router.stack.first
                      : ImpPage(
                          widget: const HomePage(),
                          transition: const FadeThroughPageTransitionsBuilder(),
                        ),
                ]);
              },
              child: const Text('Home'),
            ),
            TextButton(
              onPressed: () => context.userRepo.logout(),
              child: Text('Logout $userName ($userData)'),
            ),
            const TextField(decoration: InputDecoration(filled: true)),
          ],
        ),
      ),
    );
  }
}
