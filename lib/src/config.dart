import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'delegate.dart';
import 'router.dart';

typedef PageToUri = Uri? Function(Widget page);
typedef UriToPage = Widget Function(Uri uri);

class ImpRouterConfig extends RouterConfig<ImpRouteInformation> {
  ImpRouterConfig({
    required ImpRouter router,
  }) : super(
          routeInformationProvider: ImpRouteInformationProvider(),
          routeInformationParser: ImpRouteInformationParser(),
          routerDelegate: ImpDelegate(router: router),
          backButtonDispatcher: RootBackButtonDispatcher(),
        );
}

class ImpRouteInformationProvider extends PlatformRouteInformationProvider {
  ImpRouteInformationProvider()
      : super(
          initialRouteInformation: RouteInformation(
            uri: Uri.parse(
              WidgetsBinding.instance.platformDispatcher.defaultRouteName,
            ),
          ),
        );
}

class ImpRouteInformationParser
    extends RouteInformationParser<ImpRouteInformation> {
  @override
  Future<ImpRouteInformation> parseRouteInformation(
      RouteInformation routeInformation) {
    return SynchronousFuture(routeInformation.routeInfo);
  }

  @override
  RouteInformation? restoreRouteInformation(ImpRouteInformation configuration) {
    return RouteInformation(
      uri: configuration.uri,
      state: configuration.pageHash,
    );
  }
}

class ImpRouteInformation {
  final Uri uri;
  final int? pageHash;

  ImpRouteInformation({required this.uri, required this.pageHash});

  @override
  String toString() {
    return 'RouteInfo($uri, pageHash=$pageHash)';
  }
}

extension on RouteInformation {
  ImpRouteInformation get routeInfo {
    return ImpRouteInformation(
      uri: uri,
      pageHash: state is int ? state as int : null,
    );
  }
}
