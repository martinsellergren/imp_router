## 0.3.7

* Fix uncaught error when disposing: "setState() or markNeedsBuild() called when widget tree was locked".

## 0.3.6

* Bump rxdart.

## 0.3.5

* Avoid recreate initial page when router's ephemeral state is recreated but router's main state is not.

## 0.3.4

* Fix initialization.

## 0.3.3

* Remove initial page transition.

## 0.3.2

* Disable hero animations by default.

## 0.3.1

* Support disableThrottling.

## 0.3.0

* Support throttleDuration.

## 0.2.2

* Fix bug related to popping pageless routes.

## 0.2.1

* Make sure to always pop correct route.
* Don't allow popping last route.

## 0.2.0

* Support transition duration when pushing, plus add more predefined page transitions.
* Remove transition defaults when pushing.
* Remove ImpRouter.forceBackSwipeableTransitionsOnIos.
* Fix preserve state of single route stack when replacing current.
* Let Route.name return the uri.

## 0.1.1

* Support PopScope with android back button.

## 0.1.0

* Initial.
