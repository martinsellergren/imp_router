import 'package:flutter/material.dart';

final authors = [
  'Stieg Larsson',
  'Astrid Lindgren',
  'Lina Wolff',
  'John Ajvide Lindqvist',
];

class AuthorsBody extends StatelessWidget {
  const AuthorsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.pink,
      child: ListView(
        children: authors.map((e) => ListTile(title: Text(e))).toList(),
      ),
    );
  }
}
