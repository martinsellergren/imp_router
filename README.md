Imperative navigation using flutter's Router, to overcome limitations of the plain Navigator.

## Features

Push and pop pages programmatically, basically like we do with flutter's [Navigator](https://docs.flutter.dev/ui/navigation#using-the-navigator). Plus some nice extra features and improvements.

- All platforms: In addition to push and pop, there's also updateCurrent, to pass new parameters to current page.
- Web: Support browser's backward and forward buttons (including preserving state when revisiting a page).
- Web: Always stay in sync with browser's address bar.
- Web: Support redirections.
- Android: Intelligently handle back button (including undo updateCurrent).
- All platforms: Support passing custom transitions to any push.
- All platforms: Easily listen on navigation changes.
- All platforms: Specify a persistent overlay page, based on some app state.

## Getting started


ImpRouter(
    initialPage: const HomePage(),
    pageToUri: pageToUri,
    uriToPage: uriToPage,
    forceBackSwipeableTransitionsOnIos: true,
  )

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart
const like = 'sample';
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
