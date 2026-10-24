import 'package:app_theme/src/app_theme_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Receives the theme pair and the selected mode for an app's `MaterialApp`.
typedef AppThemeWidgetBuilder = Widget Function(
  BuildContext context,
  ThemeData lightTheme,
  ThemeData darkTheme,
  ThemeMode themeMode,
);

/// Rebuilds an app's `MaterialApp` whenever the [controller] changes.
///
/// Also folds in the platform's high-contrast request and the desktop color
/// schemes: a palette supplied by [controller]'s source wins, then
/// [dynamicColors], then the locally generated Material 3 palette.
///
/// ```dart
/// AppThemeBuilder(
///   controller: controller,
///   dynamicColors: dynamicColors,
///   builder: (context, light, dark, mode) => MaterialApp.router(
///     theme: light,
///     darkTheme: dark,
///     themeMode: mode,
///     routerConfig: router,
///   ),
/// );
/// ```
class AppThemeBuilder extends StatelessWidget {
  /// Creates the builder.
  const new({
    required this.controller,
    required this.builder,
    super.key,
    this.dynamicColors,
  });

  /// The controller that owns the theme selection.
  final AppThemeController controller;

  /// Builds the app from the resolved themes.
  final AppThemeWidgetBuilder builder;

  /// System-derived color schemes, when the platform provides them.
  final AppDynamicColorSchemes? dynamicColors;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final highContrast = MediaQuery.maybeOf(context)?.highContrast ?? false;
        final palette = controller.palette ?? dynamicColors;
        return builder(
          context,
          controller.lightTheme(
            highContrast: highContrast,
            dynamicScheme: palette?.light,
          ),
          controller.darkTheme(
            highContrast: highContrast,
            dynamicScheme: palette?.dark,
          ),
          controller.mode,
        );
      },
    );
  }
}
