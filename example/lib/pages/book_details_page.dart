import 'package:flutter/material.dart';

import '../shared.dart';

class BookDetailsPage extends StatelessWidget {
  final String title;

  const BookDetailsPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const MyBackButton(),
        title: Text(title),
      ),
    );
  }
}
