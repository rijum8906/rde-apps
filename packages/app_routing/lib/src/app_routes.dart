import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// A typed destination in the application router.
///
/// Every route owns its path and the design-system transition used when it is
/// opened, so navigation names can never drift from the router table.
sealed class AppRoute {
  const new({
    required this.location,
    this.transition = AppPageTransition.sharedAxisX,
  });

  /// The path used by `go_router`.
  final String location;

  /// The transition played when this route is opened.
  final AppPageTransition transition;

  /// The home route.
  static const AppRoute home = HomeRoute();

  /// The workspace detail route.
  static const AppRoute details = DetailsRoute();
}

/// The home destination, rendered by the gallery.
final class HomeRoute extends AppRoute {
  /// Creates the home route.
  const new({super.transition}) : super(location: '/');
}

/// The detail destination, used to demonstrate page transitions.
final class DetailsRoute extends AppRoute {
  /// Creates the detail route.
  const new({super.transition}) : super(location: '/details');
}

/// Typed navigation helpers for [BuildContext].
extension AppNavigationX on BuildContext {
  /// Replaces the current location with [route].
  void goTo(AppRoute route) => GoRouter.of(this).go(route.location);

  /// Pushes [route] on top of the current location.
  void pushRoute(AppRoute route) => GoRouter.of(this).push(route.location);

  /// Returns `true` when the router can pop the current page.
  bool canPopRoute() => GoRouter.of(this).canPop();
}
