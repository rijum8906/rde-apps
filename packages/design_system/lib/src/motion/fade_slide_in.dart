import 'package:design_system/src/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// The axis along which [FadeSlideIn] moves its child.
enum FadeSlideAxis {
  /// Moves horizontally.
  horizontal,

  /// Moves vertically.
  vertical,
}

/// Fades and slides [child] into place when it is first built.
///
/// The duration, curve, and delay come from the centralized motion tokens. The
/// widget is skipped entirely when reduced motion is requested.
class FadeSlideIn extends StatelessWidget {
  /// Creates an entrance animation.
  const new({
    required this.child,
    super.key,
    this.axis = FadeSlideAxis.vertical,
    this.distance = 24,
    this.delay = Duration.zero,
  });

  /// The content to reveal.
  final Widget child;

  /// The direction of the offset.
  final FadeSlideAxis axis;

  /// How far the child travels, in logical pixels.
  final double distance;

  /// Delay before the animation starts.
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (reduceMotion || motion.long == Duration.zero) {
      return child;
    }

    final total = motion.long + delay;
    final begin = total.inMicroseconds == 0
        ? 0.0
        : delay.inMicroseconds / total.inMicroseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: total,
      curve: Interval(begin, 1, curve: motion.emphasizedDecelerate),
      child: child,
      builder: (context, value, child) {
        final offset = switch (axis) {
          FadeSlideAxis.vertical => Offset(0, distance * (1 - value)),
          FadeSlideAxis.horizontal => Offset(distance * (1 - value), 0),
        };
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(offset: offset, child: child),
        );
      },
    );
  }
}
