import 'package:flutter/material.dart';
import 'package:imp_router/imp_router.dart';

import '../../book_details_page.dart';

final books = [
  'Flickan som lekte med elden',
  'Bröderna Lejonhjärta',
  'De polyglotta älskarna',
  'Låt den rätta komma in',
];

class BooksBody extends StatefulWidget {
  const BooksBody({super.key});

  @override
  State<BooksBody> createState() => _BooksBodyState();
}

class _BooksBodyState extends State<BooksBody> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.cyan,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: books
                  .map(
                    (e) => Builder(
                      builder: (context) => ListTile(
                        title: Text(e),
                        onTap: () => context.impRouter.push(
                          BookDetailsPage(title: e),
                          transition:
                              Theme.of(context).platform == TargetPlatform.iOS
                                  ? const CupertinoPageTransitionsBuilder()
                                  : ContainerTransformPageTransitionsBuilder(
                                      context: context,
                                    ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const TextField(
            decoration: InputDecoration(filled: true),
          ),
        ],
      ),
    );
  }
}
