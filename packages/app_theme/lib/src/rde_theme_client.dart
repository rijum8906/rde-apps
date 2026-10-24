import 'dart:async';

import 'package:app_theme/src/app_theme_settings.dart';
import 'package:app_theme/src/theme_transport.dart';
import 'package:dbus/dbus.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The bus name the RDE theme service publishes.
const String rdeThemeBusName = 'org.rde.Theme';

/// The object path the RDE theme service publishes.
const String rdeThemeObjectPath = '/org/rde/Theme';

const String _interface = 'org.rde.Theme';

/// Follows the `org.rde.Theme` session-bus service.
///
/// The service is the desktop's theme database: it owns the active theme, the
/// light/dark preference, and the Material 3 palette generated from the
/// theme's source color. This client turns that state into the workspace's
/// [AppThemeSettings] and [AppDynamicColorSchemes], so every app that passes it
/// to `AppThemeController` re-colors itself whenever the desktop theme changes:
///
/// ```dart
/// final client = RdeThemeClient();
/// final controller = AppThemeController(
///   store: ThemeStore(store),
///   source: client,
///   sink: client,
/// );
/// ```
///
/// The service is optional. When it is not running, or the session bus is
/// unreachable, [read] and [readPalette] return `null`, [changes] and
/// [paletteChanges] simply stay quiet, and [publish] is a no-op; the app keeps
/// its local selection.
final class RdeThemeClient
    implements ThemeSource, ThemeSink, ThemePaletteSource {
  /// Creates a client for the session-bus theme service.
  ///
  /// [bus] is for tests and for sharing an existing connection; when omitted
  /// the client owns its session-bus connection and closes it in [close].
  new({
    this.busName = rdeThemeBusName,
    this.objectPath = rdeThemeObjectPath,
    DBusClient? bus,
  }) : _bus = bus ?? DBusClient.session(),
       _ownsBus = bus == null {
    _object = DBusRemoteObject(
      _bus,
      name: busName,
      path: DBusObjectPath(objectPath),
    );
  }

  /// The bus name to follow.
  final String busName;

  /// The object path to follow.
  final String objectPath;

  final DBusClient _bus;
  final bool _ownsBus;
  late final DBusRemoteObject _object;

  final StreamController<AppThemeSettings> _settings =
      StreamController<AppThemeSettings>.broadcast();
  final StreamController<AppDynamicColorSchemes?> _palettes =
      StreamController<AppDynamicColorSchemes?>.broadcast();
  final List<StreamSubscription<DBusSignal>> _signals =
      <StreamSubscription<DBusSignal>>[];

  AppThemeSettings? _lastSettings;
  AppDynamicColorSchemes? _lastPalette;
  var _listening = false;
  var _closed = false;
  var _refreshing = false;
  var _refreshQueued = false;

  @override
  Stream<AppThemeSettings> get changes => _settings.stream;

  @override
  Stream<AppDynamicColorSchemes?> get paletteChanges => _palettes.stream;

  /// Reads the active theme's light/dark preference.
  ///
  /// Returns `null` when the service is not reachable, so the caller falls back
  /// to the locally stored selection.
  @override
  Future<AppThemeSettings?> read() async {
    try {
      await _startListening();
      return await _readSettings();
    } on Object {
      return null;
    }
  }

  /// Reads the desktop's Material palette for both brightnesses.
  ///
  /// Returns `null` when the service is not reachable or exposes no palette,
  /// in which case the app keeps its locally generated colors.
  @override
  Future<AppDynamicColorSchemes?> readPalette() async {
    try {
      await _startListening();
      return await _readPalettes();
    } on Object {
      return null;
    }
  }

  /// Persists the light/dark preference on the desktop.
  ///
  /// The service has no "system" mode, so that selection stays local: the app
  /// follows the platform brightness until the user picks light or dark.
  @override
  Future<void> publish(AppThemeSettings settings) async {
    final scheme = switch (settings.mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => null,
    };
    if (scheme == null) {
      return;
    }
    try {
      await _object.setProperty(
        _interface,
        'ColorScheme',
        DBusString(scheme),
      );
    } on Object {
      // The service is optional; the local selection stays authoritative.
    }
  }

  /// Stops following the service and closes the session-bus connection.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    for (final subscription in _signals) {
      await subscription.cancel();
    }
    _signals.clear();
    await _settings.close();
    await _palettes.close();
    if (_ownsBus) {
      await _bus.close();
    }
  }

  /// Subscribes to the service's change signals once.
  ///
  /// Every theme event re-reads the whole state instead of trusting the signal
  /// payload: the service always emits the authoritative values, and reading
  /// them keeps the client correct when several signals arrive together.
  Future<void> _startListening() async {
    if (_listening || _closed) {
      return;
    }
    _listening = true;
    for (final name in const [
      'ThemeChanged',
      'ColorSchemeChanged',
      'PaletteChanged',
    ]) {
      final stream = DBusRemoteObjectSignalStream(
        object: _object,
        interface: _interface,
        name: name,
      );
      _signals.add(
        stream.listen(
          (_) => unawaited(_refresh()),
          onError: (Object _) {
            // A vanished service simply stops emitting.
          },
        ),
      );
    }
  }

  Future<AppThemeSettings> _readSettings() async {
    final scheme = await _stringProperty('ColorScheme');
    return AppThemeSettings(
      mode: scheme == 'dark' ? ThemeMode.dark : ThemeMode.light,
    );
  }

  Future<AppDynamicColorSchemes?> _readPalettes() async {
    final theme = await _stringProperty('CurrentTheme');
    if (theme == null || theme.isEmpty) {
      return null;
    }
    final seed = _parseColor(await _stringProperty('SourceColor'));
    final light = await _paletteRoles(theme, 'light');
    final dark = await _paletteRoles(theme, 'dark');
    return RdeThemePalette.fromRoles(
      light: light,
      dark: dark,
      seedColor: seed,
    );
  }

  Future<String?> _stringProperty(String name) async {
    final value = await _object.getProperty(
      _interface,
      name,
      signature: DBusSignature('s'),
    );
    return value is DBusString ? value.value : null;
  }

  Future<Map<String, String>> _paletteRoles(String theme, String scheme) async {
    final response = await _object.callMethod(
      _interface,
      'GetPalette',
      [DBusString(theme), DBusString(scheme)],
      replySignature: DBusSignature('a{ss}'),
    );
    if (response.returnValues.isEmpty) {
      return const <String, String>{};
    }
    final value = response.returnValues.first;
    if (value is! DBusDict) {
      return const <String, String>{};
    }
    return <String, String>{
      for (final entry in value.children.entries)
        if (entry.key is DBusString && entry.value is DBusString)
          (entry.key as DBusString).value: (entry.value as DBusString).value,
    };
  }

  Future<void> _refresh() async {
    if (_closed) {
      return;
    }
    if (_refreshing) {
      _refreshQueued = true;
      return;
    }
    _refreshing = true;
    try {
      do {
        _refreshQueued = false;
        await _refreshOnce();
      } while (_refreshQueued && !_closed);
    } on Object {
      // The service went away mid-refresh; keep the last known theme on screen.
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _refreshOnce() async {
    final settings = await _readSettings();
    final palette = await _readPalettes();
    if (_closed) {
      return;
    }
    if (settings != _lastSettings) {
      _lastSettings = settings;
      _settings.add(settings);
    }
    if (palette != null && !_samePalette(palette, _lastPalette)) {
      _lastPalette = palette;
      _palettes.add(palette);
    }
  }

  static bool _samePalette(
    AppDynamicColorSchemes a,
    AppDynamicColorSchemes? b,
  ) => b != null && a.light == b.light && a.dark == b.dark;
}

/// Converts the service's Material role maps into workspace color schemes.
///
/// Role names are the service's snake_case names (`on_primary`,
/// `surface_container_high`, ...) and values are `#RRGGBB`. The service reports
/// the desktop's Material 3 palette, so the app renders identical colors to
/// Qt/KDE apps without re-deriving the palette locally. Roles a future service
/// version stops sending keep the value generated from the source color, and
/// the Material 3 fixed roles (which the service does not publish) come from
/// the same seed.
abstract final class RdeThemePalette {
  /// Builds the light and dark schemes from [light] and [dark] role maps.
  ///
  /// Returns `null` when neither map has a usable color, which tells the caller
  /// to keep its local palette. [seedColor] is the theme's source color; it
  /// only fills roles the service did not report.
  static AppDynamicColorSchemes? fromRoles({
    required Map<String, String> light,
    required Map<String, String> dark,
    Color? seedColor,
  }) {
    if (light.isEmpty && dark.isEmpty) {
      return null;
    }
    final seed = seedColor ?? AppColorSchemes.seed;
    return AppDynamicColorSchemes(
      light: _scheme(Brightness.light, light, seed),
      dark: _scheme(Brightness.dark, dark, seed),
    );
  }

  static ColorScheme _scheme(
    Brightness brightness,
    Map<String, String> roles,
    Color seed,
  ) {
    final base = switch (brightness) {
      Brightness.light => AppColorSchemes.light(seedColor: seed),
      Brightness.dark => AppColorSchemes.dark(seedColor: seed),
    };
    // copyWith keeps the generated value for every role the service omits.
    return base.copyWith(
      primary: _parseColor(roles['primary']),
      onPrimary: _parseColor(roles['on_primary']),
      primaryContainer: _parseColor(roles['primary_container']),
      onPrimaryContainer: _parseColor(roles['on_primary_container']),
      secondary: _parseColor(roles['secondary']),
      onSecondary: _parseColor(roles['on_secondary']),
      secondaryContainer: _parseColor(roles['secondary_container']),
      onSecondaryContainer: _parseColor(roles['on_secondary_container']),
      tertiary: _parseColor(roles['tertiary']),
      onTertiary: _parseColor(roles['on_tertiary']),
      tertiaryContainer: _parseColor(roles['tertiary_container']),
      onTertiaryContainer: _parseColor(roles['on_tertiary_container']),
      error: _parseColor(roles['error']),
      onError: _parseColor(roles['on_error']),
      errorContainer: _parseColor(roles['error_container']),
      onErrorContainer: _parseColor(roles['on_error_container']),
      surface: _parseColor(roles['surface']),
      onSurface: _parseColor(roles['on_surface']),
      surfaceDim: _parseColor(roles['surface_dim']),
      surfaceBright: _parseColor(roles['surface_bright']),
      surfaceContainerLowest: _parseColor(roles['surface_container_lowest']),
      surfaceContainerLow: _parseColor(roles['surface_container_low']),
      surfaceContainer: _parseColor(roles['surface_container']),
      surfaceContainerHigh: _parseColor(roles['surface_container_high']),
      surfaceContainerHighest: _parseColor(roles['surface_container_highest']),
      onSurfaceVariant: _parseColor(roles['on_surface_variant']),
      outline: _parseColor(roles['outline']),
      outlineVariant: _parseColor(roles['outline_variant']),
      shadow: _parseColor(roles['shadow']),
      scrim: _parseColor(roles['scrim']),
      inverseSurface: _parseColor(roles['inverse_surface']),
      onInverseSurface: _parseColor(roles['on_inverse_surface']),
      inversePrimary: _parseColor(roles['inverse_primary']),
      surfaceTint: _parseColor(roles['surface_tint']),
    );
  }
}

/// Parses a `#RRGGBB` or `#AARRGGBB` color, or `null` when [value] is invalid.
Color? _parseColor(String? value) {
  if (value == null) {
    return null;
  }
  final hex = value.startsWith('#') ? value.substring(1) : value;
  if (hex.length != 6 && hex.length != 8) {
    return null;
  }
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) {
    return null;
  }
  return Color(hex.length == 8 ? parsed : 0xFF000000 | parsed);
}
