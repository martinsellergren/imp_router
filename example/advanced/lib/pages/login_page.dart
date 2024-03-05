import 'package:flutter/material.dart';

import '../app.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox.shrink(),
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Enter username',
              ),
              onSubmitted: (value) {
                value.isEmpty ? null : context.userRepo.login(userName: value);
              },
            ),
          ),
        ),
      ),
    );
  }
}
