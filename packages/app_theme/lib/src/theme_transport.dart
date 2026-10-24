import 'package:app_theme/src/app_theme_settings.dart';
import 'package:design_system/design_system.dart';

/// Pushes theme changes in from outside the app.
///
/// `RdeThemeClient` implements this for the `org.rde.Theme` session-bus
/// service, and no app code has to change: a remote value wins over the local
/// preference on startup and remote changes are applied as they arrive.
abstract interface class ThemeSource {
  /// The selection currently published by the source, or `null` when it has
  /// none (for example when the service is not running).
  Future<AppThemeSettings?> read();

  /// Broadcasts selections made elsewhere.
  ///
  /// Implementations must support more than one listener and must not emit an
  /// error when the service is unavailable; they simply emit nothing.
  Stream<AppThemeSettings> get changes;
}

/// Receives local theme changes so they can be shared with other running apps.
///
/// `RdeThemeClient` implements it by writing the service's `ColorScheme`
/// property, so a change made in one app reaches every app on the desktop.
abstract interface class ThemeSink {
  /// Publishes [settings] to the shared theme service.
  Future<void> publish(AppThemeSettings settings);
}

/// Supplies the desktop's Material palettes to an app.
///
/// A [ThemeSource] may also implement this when the shared theme service
/// exposes the resolved palette, not just the theme selection. When it does,
/// `AppThemeController` follows the desktop palette automatically and the
/// local color variant steps aside, because the desktop palette is
/// authoritative. Both schemes are `null`-safe: a source that never emits
/// simply leaves the app on its locally generated colors.
abstract interface class ThemePaletteSource {
  /// The palette the desktop currently resolves for light and dark, or `null`
  /// when the service is unavailable.
  Future<AppDynamicColorSchemes?> readPalette();

  /// Broadcasts palettes whenever the desktop theme changes.
  Stream<AppDynamicColorSchemes?> get paletteChanges;
}
