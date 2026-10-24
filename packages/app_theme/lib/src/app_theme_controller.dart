import 'dart:async';

import 'package:app_theme/src/app_theme_settings.dart';
import 'package:app_theme/src/theme_store.dart';
import 'package:app_theme/src/theme_transport.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Holds the active theme for an app and keeps it in sync with its sources.
///
/// This is the unified theme entry point every app uses:
///
/// ```dart
/// final controller = AppThemeController(store: ThemeStore(store));
/// await controller.start();
/// controller.setMode(ThemeMode.dark);
/// ```
///
/// `RdeThemeClient` plugs in through [ThemeSource] and [ThemeSink], so a change
/// made anywhere updates every running app without touching the widgets. When
/// the source also implements [ThemePaletteSource], the desktop's own Material
/// palette replaces the locally generated one. Notifies listeners whenever the
/// selection or the palette changes.
final class AppThemeController extends ChangeNotifier {
  /// Creates a controller.
  ///
  /// [store] persists the selection locally. [source] and [sink] connect the
  /// controller to the shared theme service when one exists; without them the
  /// controller is a local-only source of truth.
  new({
    AppThemeSettings initial = AppThemeSettings.defaults,
    this.store,
    this.source,
    this.sink,
  }) : _settings = initial;

  /// Where the selection is persisted, when local persistence is enabled.
  final ThemeStore? store;

  /// The shared-service source, when one is connected.
  final ThemeSource? source;

  /// The shared-service sink, when one is connected.
  final ThemeSink? sink;

  AppThemeSettings _settings;
  StreamSubscription<AppThemeSettings>? _subscription;
  StreamSubscription<AppDynamicColorSchemes?>? _paletteSubscription;
  AppDynamicColorSchemes? _palette;
  var _started = false;
  var _disposed = false;

  /// The active selection.
  AppThemeSettings get settings => _settings;

  /// The desktop palette, when the connected source supplies one.
  ///
  /// While present it wins over the local color variant and over
  /// `AppThemeBuilder`'s fallback colors: the desktop theme is authoritative.
  AppDynamicColorSchemes? get palette => _palette;

  /// Whether the app follows the system brightness or forces light or dark.
  ThemeMode get mode => _settings.mode;

  /// The Material 3 dynamic color variant in use.
  AppColorVariant get variant => _settings.variant;

  /// Builds the light theme for the active selection.
  ThemeData lightTheme({
    bool highContrast = false,
    ColorScheme? dynamicScheme,
  }) => AppTheme.light(
    variant: _settings.variant,
    highContrast: highContrast,
    dynamicScheme: dynamicScheme,
  );

  /// Builds the dark theme for the active selection.
  ThemeData darkTheme({
    bool highContrast = false,
    ColorScheme? dynamicScheme,
  }) => AppTheme.dark(
    variant: _settings.variant,
    highContrast: highContrast,
    dynamicScheme: dynamicScheme,
  );

  /// Restores the selection and starts following the shared service.
  ///
  /// A value published by [ThemeSource] wins over the locally persisted one,
  /// so every app follows the service once it exists. The desktop palette, when
  /// the source provides one, is applied alongside it. Safe to call once;
  /// repeated calls are ignored.
  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;

    final sharedSource = source;
    final remote = await sharedSource?.read();
    final local = await store?.read();
    if (_disposed) {
      return;
    }
    final restored = remote ?? local;
    if (restored != null && restored != _settings) {
      _settings = restored;
      _notify();
    }
    _subscription = sharedSource?.changes.listen(apply);

    if (sharedSource case final ThemePaletteSource paletteSource) {
      _paletteSubscription = paletteSource.paletteChanges.listen(
        _applyPalette,
      );
      final palette = await paletteSource.readPalette();
      if (_disposed) {
        return;
      }
      _applyPalette(palette);
    }
  }

  /// Applies a selection received from the shared service.
  ///
  /// Unlike [select], this does not persist or publish it: the change came
  /// from the service, so echoing it back would loop.
  void apply(AppThemeSettings settings) {
    if (settings == _settings) {
      return;
    }
    _settings = settings;
    _notify();
  }

  /// Selects [mode] as the theme mode.
  void setMode(ThemeMode mode) => _select(_settings.copyWith(mode: mode));

  /// Selects [variant] as the Material 3 color variant.
  void setVariant(AppColorVariant variant) =>
      _select(_settings.copyWith(variant: variant));

  /// Selects [settings] as the active theme, persisting and publishing it.
  void select(AppThemeSettings settings) => _select(settings);

  /// Restores the defaults, forgets the stored selection, and publishes it.
  Future<void> reset() async {
    if (_settings != AppThemeSettings.defaults) {
      _settings = AppThemeSettings.defaults;
      _notify();
    }
    await store?.clear();
    await sink?.publish(_settings);
  }

  void _select(AppThemeSettings settings) {
    if (settings == _settings) {
      return;
    }
    _settings = settings;
    _notify();
    unawaited(store?.write(settings) ?? Future<void>.value());
    unawaited(sink?.publish(settings) ?? Future<void>.value());
  }

  void _applyPalette(AppDynamicColorSchemes? palette) {
    if (_disposed || palette == _palette) {
      return;
    }
    _palette = palette;
    _notify();
  }

  void _notify() {
    if (_disposed) {
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel() ?? Future<void>.value());
    unawaited(_paletteSubscription?.cancel() ?? Future<void>.value());
    super.dispose();
  }
}
