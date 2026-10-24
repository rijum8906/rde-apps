import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The selected workspace theme.
///
/// This is the value every app renders and the value the planned
/// `org.rde.Theme` service will broadcast, so its JSON form is deliberately
/// stable: `{"mode": "dark", "variant": "expressive"}`.
@immutable
final class AppThemeSettings {
  /// Creates a theme selection.
  const new({
    this.mode = ThemeMode.system,
    this.variant = AppColorVariant.expressive,
  });

  /// Decodes a selection from its stable JSON form.
  ///
  /// Unknown or missing fields fall back per field, so a newer or partially
  /// corrupt payload never resets the whole selection.
  // Analyzer false positive: a named factory must repeat the class name,
  // otherwise it is not a valid factory declaration (same as core's Result).
  // ignore: unnecessary_type_name_in_constructor
  factory AppThemeSettings.fromJson(Object? json) {
    if (json is! Map<Object?, Object?>) {
      return defaults;
    }
    return AppThemeSettings(
      mode: _byName(ThemeMode.values, json['mode'], defaults.mode),
      variant: _byName(
        AppColorVariant.values,
        json['variant'],
        defaults.variant,
      ),
    );
  }

  /// The workspace defaults: follow the platform in the expressive palette.
  static const AppThemeSettings defaults = AppThemeSettings();

  /// Whether the app follows the system brightness or forces light or dark.
  final ThemeMode mode;

  /// The Material 3 dynamic color variant used to build the theme.
  final AppColorVariant variant;

  /// Returns a copy with the given fields replaced.
  AppThemeSettings copyWith({ThemeMode? mode, AppColorVariant? variant}) =>
      AppThemeSettings(
        mode: mode ?? this.mode,
        variant: variant ?? this.variant,
      );

  /// The stable JSON form shared with the theme service.
  Map<String, Object?> toJson() => <String, Object?>{
    'mode': mode.name,
    'variant': variant.name,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppThemeSettings &&
          other.mode == mode &&
          other.variant == variant;

  @override
  int get hashCode => Object.hash(mode, variant);

  @override
  String toString() => 'AppThemeSettings(mode: $mode, variant: $variant)';

  static T _byName<T extends Enum>(List<T> values, Object? name, T fallback) {
    if (name is! String) {
      return fallback;
    }
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return fallback;
  }
}
