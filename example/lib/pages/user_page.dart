import 'package:flutter/material.dart';
import 'package:imp_router/imp_router.dart';

import '../app.dart';
import '../shared.dart';

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
              onPressed: () => context.impRouter.pushNewStack(
                [context.impRouter.currentStack!.first],
              ),
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
