import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Builds the widget that renders an [AppRoute].
typedef AppRoutePageBuilder = Widget Function(
  BuildContext context,
  GoRouterState state,
);

/// A typed destination in the application route table.
///
/// Every route owns its path, a stable name, and the design-system transition
/// played when it is opened, so navigation identifiers can never drift from
/// the router table:
///
/// ```dart
/// abstract final class AppRoutes {
///   /// The home destination.
///   static const AppRoute home = AppRoute(path: '/', name: 'home');
/// }
/// ```
@immutable
final class AppRoute {
  /// Creates a route at [path] with a unique [name].
  const new({
    required this.path,
    required this.name,
    this.transition = AppPageTransition.sharedAxisX,
  }) : assert(path.length > 0, 'A route path cannot be empty.');

  /// The path registered with `go_router`.
  final String path;

  /// The unique route name, used for diagnostics and deep links.
  final String name;

  /// The transition played when the page is opened.
  final AppPageTransition transition;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppRoute &&
          other.path == path &&
          other.name == name &&
          other.transition == transition;

  @override
  int get hashCode => Object.hash(path, name, transition);

  @override
  String toString() => 'AppRoute($path)';
}

/// A route bound to the widget that renders it.
@immutable
final class AppPage {
  /// Creates a page that renders [route] through [builder].
  const new({required this.route, required this.builder});

  /// The destination this page renders.
  final AppRoute route;

  /// Builds the page content.
  final AppRoutePageBuilder builder;
}

/// Navigates between the branches of a tabbed shell.
///
/// The shell builder receives one of these so hosts can drive a
/// `NavigationRail` or a `NavigationBar` without depending on `go_router`
/// directly.
final class AppShellNavigation {
  /// Wraps the `go_router` navigation shell.
  const new(this._shell);

  final StatefulNavigationShell _shell;

  /// The index of the selected branch.
  int get currentIndex => _shell.currentIndex;

  /// Selects the branch at [index].
  ///
  /// Re-selecting the active branch returns it to its initial location, which
  /// matches the Material navigation-bar behaviour.
  void goToBranch(int index) =>
      _shell.goBranch(index, initialLocation: index == _shell.currentIndex);
}

/// Typed navigation helpers for [BuildContext].
extension AppNavigationX on BuildContext {
  /// Replaces the current location with [route].
  void goTo(AppRoute route) => GoRouter.of(this).go(route.path);

  /// Pushes [route] on top of the current location.
  void pushRoute(AppRoute route) => GoRouter.of(this).push(route.path);

  /// Returns `true` when the router can pop the current page.
  bool canPopRoute() => GoRouter.of(this).canPop();

  /// Whether [route] is the current location.
  bool isRouteActive(AppRoute route) =>
      GoRouter.of(this).state.matchedLocation == route.path;

  /// A listenable that notifies whenever the active location changes.
  ///
  /// Pages use it to restore focus when their branch becomes active again.
  Listenable get routeChanges => GoRouter.of(this).routerDelegate;
}
