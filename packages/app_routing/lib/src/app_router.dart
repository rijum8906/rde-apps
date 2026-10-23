import 'package:app_routing/src/app_routes.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Builds the chrome that hosts a tabbed app shell.
///
/// [child] is the indexed stack of the shell's branches. Hosts wrap it in a
/// `NavigationRail` on wide windows and a `NavigationBar` on narrow ones,
/// driven by [navigation].
typedef AppShellBuilder = Widget Function(
  BuildContext context,
  AppShellNavigation navigation,
  Widget child,
);

/// A thin, typed wrapper around [GoRouter].
///
/// The wrapper owns the route table and registers the design-system page
/// transitions through [CustomTransitionPage]. Hosts only declare their pages:
///
/// ```dart
/// final router = AppRouter(
///   pages: [AppPage(route: AppRoutes.home, builder: (_, _) => const Home())],
///   routes: [AppPage(route: AppRoutes.details, builder: (_, _) => const D())],
/// );
/// MaterialApp.router(routerConfig: router.router);
/// ```
///
/// Passing a `shell` turns the pages into branches of an indexed stack, so
/// every tab keeps its own navigation state and scroll position while the
/// shared providers above `MaterialApp` stay alive:
///
/// ```dart
/// final router = AppRouter(
///   pages: [calculator, history, settings],
///   routes: [about],
///   shell: (context, navigation, child) =>
///       AppShell(navigation: navigation, child: child),
/// );
/// ```
final class AppRouter {
  /// Creates the router for [pages], optional pushed [routes], and an optional
  /// tabbed [shell].
  ///
  /// [pages] must contain at least one page; its first entry is the initial
  /// location unless [initialLocation] overrides it. When [shell] is provided,
  /// every page becomes a shell branch, so at least two pages are required.
  /// [errorBuilder] replaces the built-in not-found page.
  new({
    required List<AppPage> pages,
    List<AppPage> routes = const [],
    AppShellBuilder? shell,
    String? initialLocation,
    this.errorBuilder,
  }) : assert(pages.isNotEmpty, 'Register at least one page.'),
       assert(
         shell == null || pages.length > 1,
         'A tabbed shell needs at least two pages.',
       ),
       _pages = List<AppPage>.unmodifiable(pages),
       _routes = List<AppPage>.unmodifiable(routes),
       _shell = shell,
       _initialLocation = initialLocation ?? pages.first.route.path;

  /// Builds the page shown when no route matches. When `null`, the router
  /// renders its built-in not-found page.
  final AppRoutePageBuilder? errorBuilder;

  final List<AppPage> _pages;
  final List<AppPage> _routes;
  final AppShellBuilder? _shell;
  final String _initialLocation;

  /// The underlying router.
  late final GoRouter router = _buildRouter();

  /// Disposes the router and its route state.
  void dispose() => router.dispose();

  GoRouter _buildRouter() {
    assert(
      {
            for (final page in [..._pages, ..._routes]) page.route.path,
          }.length ==
          _pages.length + _routes.length,
      'Route paths must be unique.',
    );

    return GoRouter(
      initialLocation: _initialLocation,
      routes: [
        if (_shell case final shell?)
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) => shell(
              context,
              AppShellNavigation(navigationShell),
              navigationShell,
            ),
            branches: [
              for (final page in _pages)
                StatefulShellBranch(routes: [_buildRoute(page)]),
            ],
          )
        else
          ..._pages.map(_buildRoute),
        ..._routes.map(_buildRoute),
      ],
      errorBuilder: _buildError,
    );
  }

  Widget _buildError(BuildContext context, GoRouterState state) {
    final custom = errorBuilder;
    if (custom != null) {
      return custom(context, state);
    }
    return _RouteNotFoundPage(
      location: state.uri.toString(),
      onGoHome: () => context.goTo(_pages.first.route),
    );
  }

  GoRoute _buildRoute(AppPage page) {
    return GoRoute(
      path: page.route.path,
      name: page.route.name,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        name: page.route.name,
        transitionDuration: AppPageTransitions.duration,
        // The framework's 300 ms default matches the design system's reverse
        // token, so leaving pages are deliberately left on it.
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return AppPageTransitions.build(
            animation: animation,
            child: child,
            transition: page.route.transition,
            disableAnimations:
                MediaQuery.maybeOf(context)?.disableAnimations ?? false,
          );
        },
        child: page.builder(context, state),
      ),
    );
  }
}

class _RouteNotFoundPage extends StatelessWidget {
  const new({required this.location, required this.onGoHome});

  final String location;
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Page not found',
      body: EmptyState(
        title: 'This page does not exist',
        message: 'Nothing is registered at $location.',
        icon: Icons.explore_off_outlined,
        action: AppButton(
          label: 'Go to start',
          icon: Icons.home_outlined,
          variant: AppButtonVariant.tonal,
          onPressed: onGoHome,
        ),
      ),
    );
  }
}
