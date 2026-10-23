import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [child] inside a themed app, optionally requesting reduced motion.
Widget _host(Widget child, {ThemeData? theme, bool disableAnimations = false}) {
  return MaterialApp(
    theme: theme ?? AppTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: child,
    ),
  );
}

/// Verifies the Material 3 Expressive theme, tokens, and color variants.
void main() {
  group('AppTheme', () {
    test('light and dark themes carry the scheme and extensions', () {
      final light = AppTheme.light();
      final dark = AppTheme.dark();

      expect(light.colorScheme.brightness, Brightness.light);
      expect(dark.colorScheme.brightness, Brightness.dark);
      expect(light.useMaterial3, isTrue);
      expect(light.extension<AppTextTheme>(), isNotNull);
      expect(light.extension<AppShapes>(), isNotNull);
      expect(light.extension<AppMotionTokens>(), isNotNull);
    });

    test('every expressive variant produces a distinct scheme', () {
      final primaries = <Color>{
        for (final variant in AppColorVariant.values)
          AppColorSchemes.light(variant: variant).primary,
      };

      // Monochrome and neutral can resolve to the same tonal value, so the
      // palette count is asserted as a lower bound rather than an equality.
      expect(primaries.length, greaterThanOrEqualTo(6));
      expect(AppColorVariant.values, hasLength(7));
      expect(AppColorVariant.expressive.materialVariant.name, 'expressive');
      expect(AppColorVariant.values.first.label, 'Expressive');
    });

    test('high contrast raises the generated contrast level', () {
      final normal = AppColorSchemes.light();
      final high = AppColorSchemes.light(contrastLevel: 1);

      expect(high, isNot(equals(normal)));
      expect(high.brightness, Brightness.light);
    });

    test('a dynamic scheme overrides the seed scheme', () {
      const dynamic = ColorScheme.light(primary: Color(0xFF00FF00));
      final theme = AppTheme.light(dynamicScheme: dynamic);

      expect(theme.colorScheme.primary, const Color(0xFF00FF00));
    });

    test('high contrast wins over dynamic color', () {
      const dynamic = ColorScheme.light(primary: Color(0xFF00FF00));
      final theme = AppTheme.light(dynamicScheme: dynamic, highContrast: true);

      expect(theme.colorScheme.primary, isNot(const Color(0xFF00FF00)));
    });

    test('typography exposes the full scale and emphasis styles', () {
      final text = AppTypography.scaleFor(colorScheme: AppColorSchemes.light());
      final appText = text.asAppTextTheme;

      expect(text.displayLarge, isNotNull);
      expect(text.labelSmall, isNotNull);
      expect(appText.emphasisLarge.fontWeight, FontWeight.w700);
      expect(appText.emphasisMedium.fontWeight, FontWeight.w600);
      expect(appText.scale.bodyMedium, isNotNull);
    });

    test('shape scale grows monotonically', () {
      const shapes = AppShapes.expressive;

      expect(shapes.extraSmall, lessThan(shapes.small));
      expect(shapes.small, lessThan(shapes.medium));
      expect(shapes.medium, lessThan(shapes.large));
      expect(shapes.large, lessThan(shapes.extraLarge));
      expect(shapes.pillShape, isA<StadiumBorder>());
    });
  });

  group('Accessibility', () {
    testWidgets('reduced motion collapses every duration token', (
      tester,
    ) async {
      late AppMotionTokens tokens;

      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) {
              tokens = context.motion;
              return const SizedBox.shrink();
            },
          ),
          disableAnimations: true,
        ),
      );

      expect(tokens.short, Duration.zero);
      expect(tokens.medium, Duration.zero);
      expect(tokens.long, Duration.zero);
      expect(tokens.extraLong, Duration.zero);
      expect(tokens.stagger, Duration.zero);
    });

    testWidgets('normal motion keeps the tokens intact', (tester) async {
      late AppMotionTokens tokens;

      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) {
              tokens = context.motion;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(tokens.short, AppDurations.short);
      expect(tokens.long, AppDurations.long);
    });

    testWidgets('page transitions are skipped when motion is disabled', (
      tester,
    ) async {
      const child = Text('page');

      await tester.pumpWidget(
        _host(
          AppPageTransitions.build(
            animation: const AlwaysStoppedAnimation<double>(0.5),
            child: child,
            disableAnimations: true,
          ),
        ),
      );

      expect(find.text('page'), findsOneWidget);
    });

    testWidgets('theme text accessor reads the emphasis styles', (
      tester,
    ) async {
      late AppTextTheme text;

      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) {
              text = context.text;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(text.emphasisLarge.fontWeight, FontWeight.w700);
      expect(text.scale.titleLarge, isNotNull);
    });
  });
}
