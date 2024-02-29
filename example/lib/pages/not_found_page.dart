import 'package:flutter/material.dart';
import 'package:imp_router/imp_router.dart';

import 'home/home_page.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Not found'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.impRouter.pop(fallback: const HomePage()),
          child: const Text('Go home'),
        ),
      ),
    );
  }
}
