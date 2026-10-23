import 'package:app_routing/app_routing.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the typed route table and the go_router integration.
void main() {
  test('typed routes expose stable locations and transitions', () {
    expect(AppRoute.home.location, '/');
    expect(AppRoute.details.location, '/details');
    expect(AppRoute.details.transition, AppPageTransition.sharedAxisX);
    expect(
      const DetailsRoute(transition: AppPageTransition.fadeThrough).transition,
      AppPageTransition.fadeThrough,
    );
  });

  testWidgets('router navigates between typed destinations', (tester) async {
    final router = AppRouter(
      homeBuilder: (context, state) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => context.pushRoute(AppRoute.details),
            child: const Text('open details'),
          ),
        ),
      ),
      detailsBuilder: (context, state) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => context.goTo(AppRoute.home),
            child: const Text('details page'),
          ),
        ),
      ),
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router.router),
    );
    await tester.pumpAndSettle();

    expect(find.text('open details'), findsOneWidget);

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
}
