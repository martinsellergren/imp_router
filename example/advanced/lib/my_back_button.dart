import 'package:flutter/material.dart';
import 'package:imp_router/imp_router.dart';

import 'pages/home/home_page.dart';

class MyBackButton extends StatelessWidget {
  const MyBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BackButton(
      onPressed: () => context.impRouter.pop(
        fallback: const HomePage(),
      ),
    );
  }
}
