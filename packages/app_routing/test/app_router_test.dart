import 'package:app_routing/app_routing.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const AppRoute _home = AppRoute(path: '/', name: 'home');
const AppRoute _details = AppRoute(path: '/details', name: 'details');
const AppRoute _inbox = AppRoute(path: '/inbox', name: 'inbox');
const AppRoute _profile = AppRoute(path: '/profile', name: 'profile');

/// Verifies the typed route table and the go_router integration.
void main() {
  test('routes compare by value and expose their transition', () {
    expect(_home, const AppRoute(path: '/', name: 'home'));
    expect(
      _home ==
          const AppRoute(
            path: '/',
            name: 'home',
            transition: AppPageTransition.fadeThrough,
          ),
      isFalse,
    );
    expect(
      const AppRoute(
        path: '/x',
        name: 'x',
        transition: AppPageTransition.sharedAxisY,
      ).transition,
      AppPageTransition.sharedAxisY,
    );
    expect(_home.toString(), 'AppRoute(/)');
  });

  testWidgets('router pushes and pops typed destinations', (tester) async {
    final router = AppRouter(
      pages: [
        AppPage(
          route: _home,
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.pushRoute(_details),
                child: const Text('open details'),
              ),
            ),
          ),
        ),
      ],
      routes: [
        AppPage(
          route: _details,
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.goTo(_home),
                child: const Text('details page'),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router.router),
    );
    await tester.pumpAndSettle();

    expect(find.text('open details'), findsOneWidget);
    expect(router.router.state.matchedLocation, '/');

    await tester.tap(find.text('open details'));
    await tester.pumpAndSettle();

    expect(find.text('details page'), findsOneWidget);
    expect(router.router.state.matchedLocation, '/details');
    expect(router.router.canPop(), isTrue);

    await tester.tap(find.text('details page'));
    await tester.pumpAndSettle();

    expect(find.text('open details'), findsOneWidget);
    expect(router.router.state.matchedLocation, '/');
  });

  testWidgets('shell switches branches and keeps each branch state', (
    tester,
  ) async {
    final router = AppRouter(
      pages: [
        AppPage(route: _inbox, builder: (_, _) => const _CounterPage()),
        AppPage(
          route: _profile,
          builder: (_, _) => const Center(child: Text('profile page')),
        ),
      ],
      shell: (context, navigation, child) => Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigation.currentIndex,
          onDestinationSelected: navigation.goToBranch,
          destinations: const [
            NavigationDestination(label: 'Inbox', icon: Icon(Icons.inbox)),
            NavigationDestination(label: 'Profile', icon: Icon(Icons.person)),
          ],
        ),
      ),
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router.router),
    );
    await tester.pumpAndSettle();

    expect(find.text('count 0'), findsOneWidget);

    await tester.tap(find.text('Increment'));
    await tester.pump();
    expect(find.text('count 1'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('profile page'), findsOneWidget);
    expect(router.router.state.matchedLocation, '/profile');

    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();
    expect(find.text('count 1'), findsOneWidget);
  });

  testWidgets('unknown locations render the not-found page', (tester) async {
    final router = AppRouter(
      pages: [
        AppPage(
          route: _home,
          builder: (_, _) => const Center(child: Text('home page')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router.router),
    );
    await tester.pumpAndSettle();

    router.router.go('/missing');
    await tester.pumpAndSettle();

    expect(find.text('This page does not exist'), findsOneWidget);
    expect(find.textContaining('/missing'), findsOneWidget);

    await tester.tap(find.text('Go to start'));
    await tester.pumpAndSettle();
    expect(find.text('home page'), findsOneWidget);
  });
}

class _CounterPage extends StatefulWidget {
  const new();

  @override
  State<_CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<_CounterPage> {
  var _count = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('count $_count'),
          TextButton(
            onPressed: () => setState(() => _count++),
            child: const Text('Increment'),
          ),
        ],
      ),
    );
  }
}
