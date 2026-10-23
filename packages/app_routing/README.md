# app_routing

Typed `go_router` navigation for the workspace. `AppRoute` is a sealed route
model: each destination owns its path and the design-system page transition it
opens with, and `AppRouter` registers those transitions with `go_router` via
`CustomTransitionPage` using the centralized motion durations. Host apps get
typed `goTo`/`pushRoute` helpers and never write paths by hand. `detailsBuilder`
is optional, so a single-screen app can register only the home route.

```dart
final router = AppRouter(
  homeBuilder: (context, state) => const HomeScreen(),
  detailsBuilder: (context, state) => const DetailsScreen(),
);

MaterialApp.router(routerConfig: router.router);

// Later, from any widget below the router:
onPressed: () => context.pushRoute(AppRoute.details),
```
