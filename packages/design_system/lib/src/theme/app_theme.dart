import 'package:design_system/src/theme/color_schemes.dart';
import 'package:design_system/src/theme/motion.dart';
import 'package:design_system/src/theme/shapes.dart';
import 'package:design_system/src/theme/typography.dart';
import 'package:flutter/material.dart';

/// Builds Material 3 Expressive [ThemeData] for the workspace.
///
/// ```dart
/// MaterialApp(
///   theme: AppTheme.light(),
///   darkTheme: AppTheme.dark(),
///   themeMode: ThemeMode.system,
///   home: const HomeScreen(),
/// );
/// ```
///
/// Dynamic (system) colors can be supplied through `dynamicScheme`; when the
/// platform has none, the static seed is used. High-contrast requests always
/// win over dynamic colors so the accessibility guarantee is never lost.
abstract final class AppTheme {
  /// Creates the light theme.
  static ThemeData light({
    AppColorVariant variant = AppColorVariant.expressive,
    ColorScheme? dynamicScheme,
    bool highContrast = false,
    Color seedColor = AppColorSchemes.seed,
  }) {
    return _build(
      _scheme(
        brightness: Brightness.light,
        variant: variant,
        dynamicScheme: dynamicScheme,
        highContrast: highContrast,
        seedColor: seedColor,
      ),
    );
  }

  /// Creates the dark theme.
  static ThemeData dark({
    AppColorVariant variant = AppColorVariant.expressive,
    ColorScheme? dynamicScheme,
    bool highContrast = false,
    Color seedColor = AppColorSchemes.seed,
  }) {
    return _build(
      _scheme(
        brightness: Brightness.dark,
        variant: variant,
        dynamicScheme: dynamicScheme,
        highContrast: highContrast,
        seedColor: seedColor,
      ),
    );
  }

  static ColorScheme _scheme({
    required Brightness brightness,
    required AppColorVariant variant,
    required ColorScheme? dynamicScheme,
    required bool highContrast,
    required Color seedColor,
  }) {
    final contrastLevel = highContrast ? 1.0 : 0.0;
    if (dynamicScheme != null && !highContrast) {
      return dynamicScheme;
    }
    return switch (brightness) {
      Brightness.light => AppColorSchemes.light(
        variant: variant,
        seedColor: seedColor,
        contrastLevel: contrastLevel,
      ),
      Brightness.dark => AppColorSchemes.dark(
        variant: variant,
        seedColor: seedColor,
        contrastLevel: contrastLevel,
      ),
    };
  }

  static ThemeData _build(ColorScheme scheme) {
    final textTheme = AppTypography.scaleFor(colorScheme: scheme);
    const shapes = AppShapes.expressive;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[
        textTheme.asAppTextTheme,
        shapes,
        AppMotionTokens.standardTokens,
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: scheme.surfaceTint,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        // Tonal surfaces: color comes from the scheme, the tint handles
        // elevation instead of an arbitrary drop shadow.
        color: scheme.surfaceContainerLow,
        surfaceTintColor: scheme.surfaceTint,
        shadowColor: scheme.shadow,
        elevation: 1,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: shapes.cardShape,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: scheme.surfaceTint,
        elevation: 3,
        shape: shapes.dialogShape,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: scheme.onSurface,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: _inputBorder(shapes, BorderSide.none),
        enabledBorder: _inputBorder(
          shapes,
          BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: _inputBorder(
          shapes,
          BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: _inputBorder(shapes, BorderSide(color: scheme.error)),
        focusedErrorBorder: _inputBorder(
          shapes,
          BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: shapes.pillShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: shapes.pillShape,
          side: BorderSide(color: scheme.outline),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: shapes.pillShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: shapes.smallShape,
        iconColor: scheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: shapes.smallShape,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: scheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(shapes.extraLarge),
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(shapes.extraSmall),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(AppShapes shapes, BorderSide side) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(shapes.small),
      borderSide: side,
    );
  }
}
