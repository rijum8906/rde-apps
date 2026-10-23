import 'package:app_routing/src/app_routes.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Builds the widget for a typed [AppRoute].
typedef AppRoutePageBuilder = Widget Function(
  BuildContext context,
  GoRouterState state,
);

/// A thin, typed wrapper around [GoRouter].
///
/// The wrapper owns the route table and registers the design-system page
/// transitions with `go_router` through [CustomTransitionPage]. Hosts only
/// provide the page content:
///
/// ```dart
/// final router = AppRouter(
///   homeBuilder: (context, state) => const HomeScreen(),
///   detailsBuilder: (context, state) => const DetailsScreen(),
/// );
/// MaterialApp.router(routerConfig: router.router);
/// ```
final class AppRouter {
  /// Creates the router with the workspace route table.
  ///
  /// [detailsBuilder] is optional: single-screen apps only register the home
  /// route, while multi-page hosts also register the detail route.
  new({
    required this.homeBuilder,
    this.detailsBuilder,
    this.initialLocation = '/',
  });

  /// Builds the home page.
  final AppRoutePageBuilder homeBuilder;

  /// Builds the detail page. When `null`, the detail route is not registered.
  final AppRoutePageBuilder? detailsBuilder;

  /// The location shown on first launch.
  final String initialLocation;

  /// The underlying router.
  late final GoRouter router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      _buildRoute(AppRoute.home, homeBuilder),
      if (detailsBuilder != null)
        _buildRoute(AppRoute.details, detailsBuilder!),
    ],
  );

  /// Disposes the router and its route state.
  void dispose() => router.dispose();

  GoRoute _buildRoute(AppRoute route, AppRoutePageBuilder builder) {
    return GoRoute(
      path: route.location,
      name: route.location,
      pageBuilder: (context, state) {
        return CustomTransitionPage<void>(
          key: state.pageKey,
          name: route.location,
          transitionDuration: AppPageTransitions.duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return AppPageTransitions.build(
              animation: animation,
              child: child,
              transition: route.transition,
              disableAnimations:
                  MediaQuery.maybeOf(context)?.disableAnimations ?? false,
            );
          },
          child: builder(context, state),
        );
      },
    );
  }
}
