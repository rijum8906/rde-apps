import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The preferences that personalize the calculator.
///
/// These are presentation preferences rather than business rules, so the model
/// uses the theme and math enums directly instead of duplicating them.
/// Instances are immutable and compared by value.
@immutable
final class AppSettings {
  /// Creates a set of preferences.
  const new({
    this.themeMode = ThemeMode.system,
    this.colorVariant = AppColorVariant.expressive,
    this.angleMode = AngleMode.degrees,
  });

  /// Decodes persisted [json], falling back per field so a partially corrupt
  /// payload never resets every preference.
  // Analyzer false positive: a named factory must repeat the class name,
  // otherwise it is not a valid factory declaration (same as core's Result).
  // ignore: unnecessary_type_name_in_constructor
  factory AppSettings.fromJson(Object? json) {
    if (json is! Map<Object?, Object?>) {
      return defaults;
    }
    return AppSettings(
      themeMode: _byName(
        ThemeMode.values,
        json['themeMode'],
        defaults.themeMode,
      ),
      colorVariant: _byName(
        AppColorVariant.values,
        json['colorVariant'],
        defaults.colorVariant,
      ),
      angleMode: _byName(
        AngleMode.values,
        json['angleMode'],
        defaults.angleMode,
      ),
    );
  }

  /// The factory defaults, used on first launch and by "restore defaults".
  static const AppSettings defaults = AppSettings();

  /// Whether the app follows the system brightness or forces light or dark.
  final ThemeMode themeMode;

  /// The Material 3 dynamic color variant used to build the theme.
  final AppColorVariant colorVariant;

  /// The unit used by trigonometric functions.
  final AngleMode angleMode;

  /// Returns a copy with the given fields replaced.
  AppSettings copyWith({
    ThemeMode? themeMode,
    AppColorVariant? colorVariant,
    AngleMode? angleMode,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    colorVariant: colorVariant ?? this.colorVariant,
    angleMode: angleMode ?? this.angleMode,
  );

  /// The JSON representation persisted in the key/value store.
  Map<String, Object?> toJson() => <String, Object?>{
    'themeMode': themeMode.name,
    'colorVariant': colorVariant.name,
    'angleMode': angleMode.name,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          other.themeMode == themeMode &&
          other.colorVariant == colorVariant &&
          other.angleMode == angleMode;

  @override
  int get hashCode => Object.hash(themeMode, colorVariant, angleMode);

  @override
  String toString() =>
      'AppSettings(themeMode: $themeMode, colorVariant: $colorVariant, '
      'angleMode: $angleMode)';

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
