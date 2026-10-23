import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The workspace typography, exposing the full Material 3 type scale plus
/// expressive emphasis styles.
///
/// The base scale is a [TextTheme] so every existing Material widget keeps
/// working, while the expressive styles are available through the theme
/// extension:
///
/// ```dart
/// Text('Welcome', style: context.text.emphasisLarge);
/// Text('Caption', style: context.text.scale.labelMedium);
/// ```
@immutable
final class AppTextTheme extends ThemeExtension<AppTextTheme> {
  /// Creates a typography extension from a base [scale] and emphasis styles.
  const new({
    required this.scale,
    required this.emphasisLarge,
    required this.emphasisMedium,
    required this.emphasisSmall,
  });

  /// The complete Material 3 type scale.
  final TextTheme scale;

  /// A display-adjacent style for expressive hero headlines.
  final TextStyle emphasisLarge;

  /// A title style with expressive weight.
  final TextStyle emphasisMedium;

  /// A label style with expressive weight.
  final TextStyle emphasisSmall;

  /// Reads the typography extension from [context].
  ///
  /// Falls back to a scale derived from the ambient [Theme] when the extension
  /// is missing, so widgets stay usable in isolation (for example in tests).
  static AppTextTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppTextTheme>() ?? theme.textTheme.asAppTextTheme;
  }

  @override
  AppTextTheme copyWith({
    TextTheme? scale,
    TextStyle? emphasisLarge,
    TextStyle? emphasisMedium,
    TextStyle? emphasisSmall,
  }) {
    return AppTextTheme(
      scale: scale ?? this.scale,
      emphasisLarge: emphasisLarge ?? this.emphasisLarge,
      emphasisMedium: emphasisMedium ?? this.emphasisMedium,
      emphasisSmall: emphasisSmall ?? this.emphasisSmall,
    );
  }

  @override
  AppTextTheme lerp(covariant ThemeExtension<AppTextTheme>? other, double t) {
    if (other is! AppTextTheme) {
      return this;
    }
    return AppTextTheme(
      scale: TextTheme.lerp(scale, other.scale, t),
      emphasisLarge: TextStyle.lerp(emphasisLarge, other.emphasisLarge, t)!,
      emphasisMedium: TextStyle.lerp(emphasisMedium, other.emphasisMedium, t)!,
      emphasisSmall: TextStyle.lerp(emphasisSmall, other.emphasisSmall, t)!,
    );
  }
}

/// Adds the expressive emphasis styles to a Material [TextTheme].
extension AppTextThemeX on TextTheme {
  /// Wraps this scale into an [AppTextTheme] with expressive emphasis styles.
  AppTextTheme get asAppTextTheme {
    final emphasisLarge = (headlineMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
    );
    final emphasisMedium = (titleLarge ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    );
    final emphasisSmall = (labelLarge ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );
    return AppTextTheme(
      scale: this,
      emphasisLarge: emphasisLarge,
      emphasisMedium: emphasisMedium,
      emphasisSmall: emphasisSmall,
    );
  }
}

/// Builds the Material 3 type scale for a [ColorScheme].
abstract final class AppTypography {
  /// The full Material 3 type scale, tinted for [colorScheme].
  static TextTheme scaleFor({
    required ColorScheme colorScheme,
    TargetPlatform? platform,
  }) {
    final typography = Typography.material2021(
      platform: platform ?? defaultTargetPlatform,
      colorScheme: colorScheme,
    );
    final scale = colorScheme.brightness == Brightness.dark
        ? typography.white
        : typography.black;
    return scale.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
  }
}
