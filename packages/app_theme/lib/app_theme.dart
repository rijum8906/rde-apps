/// Unified theme selection for every workspace app.
///
/// ```dart
/// final controller = AppThemeController(store: ThemeStore(store));
/// await controller.start();
///
/// AppThemeScope(
///   controller: controller,
///   child: AppThemeBuilder(
///     controller: controller,
///     builder: (context, light, dark, mode) => MaterialApp(
///       theme: light,
///       darkTheme: dark,
///       themeMode: mode,
///       home: const HomePage(),
///     ),
///   ),
/// );
/// ```
///
/// The controller is the single source of truth for the theme in an app.
/// `RdeThemeClient` connects it to the `org.rde.Theme` session-bus service, so
/// the desktop decides the palette and every running app follows it; see the
/// package README for the protocol.
library;

export 'src/app_theme_builder.dart';
export 'src/app_theme_controller.dart';
export 'src/app_theme_scope.dart';
export 'src/app_theme_settings.dart';
export 'src/rde_theme_client.dart';
export 'src/theme_store.dart';
export 'src/theme_transport.dart';
