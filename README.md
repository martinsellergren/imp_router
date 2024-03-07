![imp](https://upload.wikimedia.org/wikipedia/commons/thumb/6/69/Imp_with_cards_-_illustration_from_Le_grand_Etteilla.jpg/300px-Imp_with_cards_-_illustration_from_Le_grand_Etteilla.jpg)

Imperative navigation in flutter. For those who prefer imperative navigation but still want to benefit from Navigation 2.0 features.

## Background

***Why another Router wrapper, when we already have go_router, beamer, and many more?***

This package aims to provide imperative navigation, as opposed to declarative. Push and pop pages programmatically, similarly to what we do with flutter's ordinary Navigator.

***Why not just use the ordinary Navigator for imperative navigation?***

This package adds some nice extra features and improvements. Mainly full support of browser's backward and forward buttons. But also some more stuff, see below.

## Features

- all platforms: In addition to `push` and `pop`, there's also `updateCurrent`, to pass new parameters to current page.
- web: Support browser's backward and forward buttons (including automatically preserving state when revisiting a page).
- web: Stay in sync with browser's address bar.
- web: Support redirections.
- android: Intelligently handle back button (including undo `updateCurrent`).
- all platforms: Support custom transitions for individual pushes.
- all platforms: Easily listen on navigation changes.
- all platforms: Display a persistent overlay page, based on some app state.

## Getting started

### Create the router

```dart
final impRouter = ImpRouter(
  initialPage: const HomePage(), // Required.
  pageToUri: // Optional. If you want navigation to update address bar on web (plus some other benefits, see below).
  uriToPage: // Optional. If you want to handle deep links/ web browser address bar/ web browser refresh.
);
```
- The ImpRouter should only be created once so do not create it in a widget's build().
- You may use this instance to listen on navigation events, through `impRouter.stackStream`.
- If you create the ImpRouter in main(), start with WidgetsFlutterBinding.ensureInitialized().
- uriToPage is unnecessary for a non-web apps with no deep-link support.
- pageToUri for non-web apps can still be useful, for attaching an id to a page, and intelligently handle android back navigation.

### Create the app

```dart
MaterialApp.router(
  routerConfig: ImpRouterConfig(router: impRouter),
)
```

## Usage

### The Uri mappers

#### pageToUri

A function that takes a page (a widget) and returns an Uri. Providing this function is not required, but necessary on web if you want the address bar to update when you navigate through the app - as well as support browser backward/forward buttons.

```dart
Uri? pageToUri(Widget page) {
  switch (page) {
    case HomePage p:
      return Uri(path: '/home/${p.currentTab.name}'); // a path parameter
    case DetailsPage p:
      return Uri(
        path: '/details',
        queryParameters: {'id': '${p.id}'}, // a query parameter
      );
    default:
      return null;
  }
}
```

Simply use the widget itself to derive any parameters, like above, and include the parameters in the url however if you like.

Providing a `pageToUri` is often good also for non-web apps - the uri can serve as an id for the page - useful e.g if listen on navigation changes through `impRouter.stackStream`. Also, it's necessary to intelligently handle android back navigation; specifically skip redundant page updates (more on that below).

#### uriToPage

A function that takes an Uri and returns a widget. Providing this function is not required, but nice on web.

```dart
Widget uriToPage(Uri uri) {
  try {
    switch (uri.pathSegments) {
      case ['home', var tabName]:
        final tab = HomeTab.values.firstWhere((e) => e.name == tabName); // parse the path parameter
        return HomePage(currentTab: tab);
      case ['details']:
        final id = int.parse(uri.queryParameters['id'] ?? ''); // parse the query parameter
        return DetailsPage(id: id);
      default:
        return const NotFoundPage(); // entered a non-existing url
    }
  } catch (_) {
    return const NotFoundPage(); // entered an url that lead to a parsing error
  }
}
```

This mapper is used when the app receives a new url to decide which page to show. A web app typically receives a new url when you manually enter an url in the address bar or when you refresh the page. A non-web app may receive an url through [deep linking](https://docs.flutter.dev/ui/navigation/deep-linking). If an url is received and no uriToPage is provided, or if it returns null for received url, then the app will show the initialPage.

### Navigate

```dart
impRouter.push(DetailsPage(id: 101))
impRouter.pop()
impRouter.updateCurrent(HomePage(currentTab: HomeTab.secondTab))
```
or access the router through the context, e.g:
```dart
context.impRouter.push(DetailsPage(id: 101))
```

#### push
- You may push a new route on top of the stack or replace current top.
- Specify a custom transition, otherwise defaults to standard transitions from the theme (`ThemeData.pageTransitionsTheme`).

#### pop
- Accepts a fallback to show in case the popped page was the only page on the stack.

#### updateCurrent
This is a nice addition to Flutters ordinary Navigator. Call this with the same widget that is currently on top, but with different parameters. The new parameters are passed to the widget, its state is preserved. You may for example pass a new *currentTab* to some page, to use the router to switch tab. This way, on web, the current tab may reflect in the browsers address bar, and browsers nav buttons will work to switch between the tabs. And on Android, back button takes you to previous tab, before popping the page. More on that below.

#### pushNewStack

Finally the router also supports pushNewStack - replace the whole stack with a new one. Can be nice in certain situations but should usually be avoided since it can be confusing to the user. Under the hood, this package relies on [Navigator.pages](https://api.flutter.dev/flutter/widgets/Navigator/pages.html) - flutter will intelligently decide how to transition to the new stack.

## Deep links etc

When using this package and the app receives a deep link (or when a web app receives a link manually entered in the address bar), the app will display the corresponding page *in a single page stack*. Meaning, popping this page results in the whole app being popped. This differs from other Router wrapping packages (like go_router), where a multiple page stack can be pushed through a single deep-link.

Handling deep links (/address bar) like this package does (deep-link -> single page stack) might seem like quite a bad limitation. But actually, I'd say, it should be preferred most of the times. It can be quite annoying for user's, browsing the web, clicking some link and ending up in an app, and then wanting to get back to the browser, having to repeatedly click the back button.

Off course sometimes the user doesn't want to go back to the browser and instead keep using the app. Such a use case is however well supported using ImpRouter, like this:
- When user is on the deep-linked app page, a single back button click (android) / back swipe (iOS) takes you straight back to the browser, BUT the in-app back button instead takes you to an in-app parent page. Just make sure the in-app back button is implemented something like this:

```dart
BackButton(
  onPressed: () => context.impRouter.pop(
    // The fallback here is necessary if you'd deep link to this page.
    // Then this page would be the only page in the stack.
    fallback: const HomePage(),
  ),
)
```

## Redirections

To add url redirections just add the mapping to uriToPage. It will go like this
1) App receives url
2) Turned to a page through uriToPage
3) Displayed, and url updated to what's returned by pageToUri

Note, the uriToPage may return same page for any number of uri's. The url that end up in the browser's address bar is always what pageToUri returns.

## Overlay

Imagine the scenario where you want to display a login page if authState != loggedIn. Then you may easily do so by calling `impRouter.setOverlay(some page)`, and when logged in `impRouter.setOverlay(null)`. Difference between this and pushing a new page is that this overlay can't be navigated away from, no matter if using android back button, iOS back swipe, browser buttons etc.

## Android back button handling

This package offers some nice android back button handling out of the box. The back button can do more than just popping current page, specifically, it may also revert page updates (`ImpRouter.updateCurrent`). For example, the first back button click reverts to previous tab, second click pops the page.

Even better, it will skip redundant page updates by default. Imaging flipping between same tabs for a long time, the you might want the back button to just go back to each tab once, in reverse order, and then pop page, instead of undoing every tab switch. This is supported using this package, and is the default behavior, but you may tweak it however you like, checkout `ImpRouter.historyTransformer`. Note though, for skipping redundant tab switches like this, you're required to provide an uri to each tab through pageToUri.

## Preserving state

In web, imagine pushing a page, then popping it through in-app back button. Now you click browser's back button, which results in the popped page being pushed back. This package makes sure that the state of the pushed back page is preserved, which works out of the box. You can tweak this behavior through the parameter `nKeepAlives`. If you have very resource demanding pages you might want to experiment with decreasing this value. 0 results in no page preservation.

Pages are preserved by keeping them in the widget tree but invisible and with disabled animations and interactivity.

## Thoughts on declarative vs imperative navigation

If you're weighing between declarative navigation (e.g GoRouter) and imperative (e.g ImpRouter/Navigator), let me just share a thought. Imagine you have a home page, a category page and a details page, and navigate home->category->detail and then on the detail page there are links to similar categories, so you continue detail->category->detail->category->detail, now what do you expect when you pop pages?

I'd say, you usually expect the exact reverse order when popping, e.g detail->category->....->home. Implementing this (stacks of arbitrary lengths) declaratively is very hard, but very easy imperatively (happens automatically).

## How does browser nav button support work?

The router stores the stack history - not just page history. When using browser's nav buttons, we actually replace the whole stack with another stack at a different point in time. This way, the nav buttons truly takes you to older/newer app states - as you would expect.

# Author

- [Martin Sellergren](https://github.com/martinsellergren)