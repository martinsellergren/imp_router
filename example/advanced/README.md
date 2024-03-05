# imp_router_example

Showcasing some more advanced features. In addition to the basic example:

- Show a login page overlay, whenever user is not logged in.
- Listen on navigation changes and print the new stack.
- web: Preserve state when back-navigating, illustrated through text fields.
- Push multiple pages, then pop them all, back to home (`ImpRouter.pushNewStack`).
- Use custom animations, including `ContainerTransformPageTransitionsBuilder`.
- usePathUrlStrategy to get rid of '#' in url.
- A technic to get statically typed uri mappings etc, with the enum NavTarget.