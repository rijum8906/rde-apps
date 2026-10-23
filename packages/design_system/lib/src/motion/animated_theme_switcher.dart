import 'package:design_system/src/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// Cross-fades theme changes with the workspace motion tokens.
///
/// This mirrors `AnimatedTheme` but always takes its duration and curve from
/// the motion tokens, and becomes instant when reduced motion is requested.
class AnimatedThemeSwitcher extends StatelessWidget {
  /// Creates an animated theme switcher.
  const new({required this.data, required this.child, super.key});

  /// The theme to animate towards.
  final ThemeData data;

  /// The subtree that receives the theme.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    return AnimatedTheme(
      data: data,
      duration: motion.long,
      curve: motion.emphasized,
      child: child,
    );
  }
}
