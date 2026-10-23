import 'package:design_system/src/theme/motion.dart';
import 'package:design_system/src/theme/shapes.dart';
import 'package:design_system/src/theme/typography.dart';
import 'package:flutter/material.dart';

/// Terse access to the design-system theme extensions.
///
/// ```dart
/// Text('Title', style: context.text.emphasisLarge);
/// Card(shape: context.shapes.cardShape);
/// AnimatedOpacity(duration: context.motion.medium);
/// ```
extension AppThemeX on BuildContext {
  /// The Material 3 type scale and expressive emphasis styles.
  AppTextTheme get text => AppTextTheme.of(this);

  /// The Material 3 Expressive shape scale.
  AppShapes get shapes => AppShapes.of(this);

  /// Motion tokens, collapsed to zero when reduced motion is requested.
  AppMotionTokens get motion => AppMotionTokens.resolve(this);

  /// The ambient color scheme.
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Whether the platform requests high-contrast colors.
  bool get highContrast => MediaQuery.maybeOf(this)?.highContrast ?? false;
}
