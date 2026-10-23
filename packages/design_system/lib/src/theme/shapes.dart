import 'package:flutter/material.dart';

/// The Material 3 Expressive shape scale.
///
/// Material 3's expressive update favors generous, rounded corners. The
/// defaults here are intentionally larger than the baseline M3 scale so every
/// surface feels soft and contemporary.
@immutable
final class AppShapes extends ThemeExtension<AppShapes> {
  /// Creates a shape scale from corner radii in logical pixels.
  const new({
    this.extraSmall = 8,
    this.small = 12,
    this.medium = 16,
    this.large = 24,
    this.extraLarge = 32,
  });

  /// The default expressive scale.
  static const AppShapes expressive = AppShapes();

  /// Corner radius for chips and badges.
  final double extraSmall;

  /// Corner radius for list tiles and inputs.
  final double small;

  /// Corner radius for buttons and small surfaces.
  final double medium;

  /// Corner radius for cards and sheets.
  final double large;

  /// Corner radius for dialogs and hero surfaces.
  final double extraLarge;

  /// The border for [extraSmall] surfaces.
  RoundedRectangleBorder get extraSmallShape => _rounded(extraSmall);

  /// The border for [small] surfaces.
  RoundedRectangleBorder get smallShape => _rounded(small);

  /// The border for [medium] surfaces.
  RoundedRectangleBorder get mediumShape => _rounded(medium);

  /// The border for [large] surfaces.
  RoundedRectangleBorder get largeShape => _rounded(large);

  /// The border for [extraLarge] surfaces.
  RoundedRectangleBorder get extraLargeShape => _rounded(extraLarge);

  /// A fully rounded pill border used by expressive buttons and chips.
  StadiumBorder get pillShape => const StadiumBorder();

  /// The border used by cards.
  RoundedRectangleBorder get cardShape => largeShape;

  /// The border used by dialogs.
  RoundedRectangleBorder get dialogShape => extraLargeShape;

  /// The radius used by input fields.
  RoundedRectangleBorder get inputShape => smallShape;

  /// Reads the shape scale from [context], falling back to [expressive].
  static AppShapes of(BuildContext context) =>
      Theme.of(context).extension<AppShapes>() ?? expressive;

  @override
  AppShapes copyWith({
    double? extraSmall,
    double? small,
    double? medium,
    double? large,
    double? extraLarge,
  }) {
    return AppShapes(
      extraSmall: extraSmall ?? this.extraSmall,
      small: small ?? this.small,
      medium: medium ?? this.medium,
      large: large ?? this.large,
      extraLarge: extraLarge ?? this.extraLarge,
    );
  }

  @override
  AppShapes lerp(covariant ThemeExtension<AppShapes>? other, double t) {
    if (other is! AppShapes) {
      return this;
    }
    return AppShapes(
      extraSmall: _lerp(extraSmall, other.extraSmall, t),
      small: _lerp(small, other.small, t),
      medium: _lerp(medium, other.medium, t),
      large: _lerp(large, other.large, t),
      extraLarge: _lerp(extraLarge, other.extraLarge, t),
    );
  }

  static RoundedRectangleBorder _rounded(double radius) =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
