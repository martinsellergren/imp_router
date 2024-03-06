## [Basic example](https://github.com/martinsellergren/imp_router/tree/main/example/basic)

Basic example app using imp_router.

- Home page with tabs and a detail page pushed with FAB.
- Path/query parameters and url parsing.
- uri<->widget mappings for full browser support.
- NotFound screen when
- Android back button and browser nav buttons can switch tabs.

## [A bit more advanced example](https://github.com/martinsellergren/imp_router/tree/main/example/advanced)

Showcasing some more advanced features. In addition to the basic example:

- Use PopScope to block android back button
  - homePage requires two back button clicks before app is closed,
  - user page always blocks (including iOS back swipe)
- Show a login page overlay, whenever user is not logged in.
- Listen on navigation changes and print the new stack.
- web: Preserve state when back-navigating, illustrated through text fields.
- Push multiple pages, then pop them all, back to home (`ImpRouter.pushNewStack`).
- Use custom animations, including `ContainerTransformPageTransitionsBuilder`.
- usePathUrlStrategy to get rid of '#' in url.
- A technic to get statically typed uri mappings etc, with the enum NavTarget.