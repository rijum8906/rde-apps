import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [child] inside a themed app, optionally disabling animations.
Widget _host(Widget child, {bool disableAnimations = false}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(body: child),
    ),
  );
}

/// Verifies the motion widgets, reduced-motion behavior, and the gallery.
void main() {
  testWidgets('AnimatedPressable scales down and springs back', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      _host(
        Center(
          child: AnimatedPressable(
            onTap: () => taps++,
            child: const SizedBox(width: 80, height: 80),
          ),
        ),
      ),
    );

    final transform = find.descendant(
      of: find.byType(AnimatedPressable),
      matching: find.byType(Transform),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(AnimatedPressable)),
    );
    // The tap recognizer fires `onTapDown` after the press timeout, then the
    // scale animation runs for its full duration.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(AppDurations.short);
    final pressedScale = tester
        .widget<Transform>(transform)
        .transform
        .storage[0];
    expect(pressedScale, lessThan(1));

    await gesture.up();
    await tester.pumpAndSettle();
    final releasedScale = tester
        .widget<Transform>(transform)
        .transform
        .storage[0];
    expect(releasedScale, closeTo(1, 0.001));
    expect(taps, 1);
  });

  testWidgets('AnimatedPressable stays static with reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        AnimatedPressable(
          onTap: () {},
          child: const SizedBox(width: 80, height: 80),
        ),
        disableAnimations: true,
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(AnimatedPressable)),
    );
    await tester.pump();

    final transform = tester.widget<Transform>(
      find.descendant(
        of: find.byType(AnimatedPressable),
        matching: find.byType(Transform),
      ),
    );
    expect(transform.transform.storage[0], closeTo(1, 0.001));

    await gesture.up();
  });

  testWidgets('FadeSlideIn animates and short-circuits for reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const FadeSlideIn(child: Text('hello'))));
    expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      _host(const FadeSlideIn(child: Text('hello')), disableAnimations: true),
    );
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('StaggeredList reveals every child after settling', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        StaggeredList(
          scrollable: false,
          itemCount: 4,
          itemBuilder: (context, index) => Text('item $index'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    for (var index = 0; index < 4; index++) {
      expect(find.text('item $index'), findsOneWidget);
    }
  });

  testWidgets('AnimatedThemeSwitcher uses the motion tokens', (tester) async {
    await tester.pumpWidget(
      _host(
        AnimatedThemeSwitcher(
          data: AppTheme.dark(),
          child: const Text('themed'),
        ),
      ),
    );

    final animatedTheme = tester.widget<AnimatedTheme>(
      find.descendant(
        of: find.byType(AnimatedThemeSwitcher),
        matching: find.byType(AnimatedTheme),
      ),
    );
    expect(animatedTheme.duration, AppDurations.long);
    expect(animatedTheme.curve, AppCurves.emphasized);
  });

  testWidgets('gallery renders and reports theme changes', (tester) async {
    tester.view
      ..physicalSize = const Size(1000, 3000)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });

    ThemeMode? selected;
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: DesignSystemGallery(
          themeMode: ThemeMode.system,
          onThemeModeChanged: (mode) => selected = mode,
          onOpenDetails: () => opened = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Material 3 Expressive'), findsOneWidget);
    expect(find.text('Buttons'), findsOneWidget);
    expect(find.byType(AppButton), findsWidgets);

    await tester.tap(find.text('Dark'));
    await tester.pump();
    expect(selected, ThemeMode.dark);

    await tester.tap(find.text('Open detail page'));
    await tester.pump();
    expect(opened, isTrue);
  });
}
