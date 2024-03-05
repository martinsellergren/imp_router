import 'package:flutter/material.dart';
import 'package:imp_router/imp_router.dart';

Uri? pageToUri(Widget page) {
  switch (page) {
    case HomePage p:
      return Uri(
        path: '/home/${p.currentTab.name}',
      );
    case DetailsPage p:
      return Uri(
        path: '/details',
        queryParameters: {'id': '${p.id}'},
      );
    case NotFoundPage _:
      return Uri(path: '/oups');
    default:
      return null;
  }
}

Widget uriToPage(Uri uri) {
  try {
    switch (uri.pathSegments) {
      case ['home', var tabName]:
        final tab = HomeTab.values.firstWhere((e) => e.name == tabName);
        return HomePage(currentTab: tab);
      case ['details']:
        final id = int.parse(uri.queryParameters['id'] ?? '');
        return DetailsPage(id: id);
      default:
        return const NotFoundPage();
    }
  } catch (_) {
    return const NotFoundPage();
  }
}

final router = ImpRouter(
  initialPage: const HomePage(),
  pageToUri: pageToUri,
  uriToPage: uriToPage,
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp.router(
    routerConfig: ImpRouterConfig(router: router),
  ));
}

enum HomeTab {
  first,
  second,
}

class HomePage extends StatelessWidget {
  final HomeTab currentTab;

  const HomePage({
    super.key,
    this.currentTab = HomeTab.first,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: switch (currentTab) {
        HomeTab.first => const Center(child: Text('First body')),
        HomeTab.second => const Center(child: Text('Second body')),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentTab.index,
        onDestinationSelected: (i) => router.updateCurrent(
          HomePage(currentTab: HomeTab.values[i]),
        ),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.first_page), label: 'first'),
          NavigationDestination(icon: Icon(Icons.last_page), label: 'second'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.impRouter.push(DetailsPage(
          id: currentTab.index,
        )),
        child: const Icon(Icons.info),
      ),
    );
  }
}

class DetailsPage extends StatelessWidget {
  final int id;

  const DetailsPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.impRouter.pop(
            // The fallback here is necessary if you'd deep link to this page.
            // Then this page would be the only page in the stack.
            fallback: const HomePage(),
          ),
        ),
      ),
      body: Center(child: Text('Details page: $id')),
    );
  }
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.impRouter.pop(
            fallback: const HomePage(),
          ),
        ),
        title: const Text('Not found'),
      ),
    );
  }
}
