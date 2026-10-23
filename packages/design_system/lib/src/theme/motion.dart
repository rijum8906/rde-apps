import 'package:flutter/material.dart';

/// Semantic duration tokens used by every animation in the workspace.
///
/// Widgets must read durations from here (or from [AppMotionTokens]) instead of
/// constructing their own [Duration] values.
abstract final class AppDurations {
  /// No animation at all. Used to short-circuit when motion is disabled.
  static const Duration instant = Duration.zero;

  /// Small state changes such as press feedback (150 ms).
  static const Duration short = Duration(milliseconds: 150);

  /// Standard transitions such as expanding a card (300 ms).
  static const Duration medium = Duration(milliseconds: 300);

  /// Larger transitions such as page changes (450 ms).
  static const Duration long = Duration(milliseconds: 450);

  /// Elaborate choreography such as staggered entrances (700 ms).
  static const Duration extraLong = Duration(milliseconds: 700);

  /// Delay between two consecutive children of a staggered animation.
  static const Duration stagger = Duration(milliseconds: 60);
}

/// Material 3 easing curves.
abstract final class AppCurves {
  /// The emphasized curve for prominent transitions.
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);

  /// A curve that starts quickly and settles gently.
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1);

  /// A curve that accelerates into the transition.
  static const Curve emphasizedAccelerate = Cubic(0.3, 0, 0.8, 0.15);

  /// The standard curve for small utility animations.
  static const Curve standard = Cubic(0.4, 0, 0.2, 1);
}

/// Spring descriptions used by spring-driven animations.
abstract final class AppSprings {
  /// A snappy spring for press feedback, without visible overshoot.
  static const SpringDescription press = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 32,
  );

  /// A softer spring that overshoots slightly for playful emphasis.
  static const SpringDescription bounce = SpringDescription(
    mass: 1,
    stiffness: 280,
    damping: 18,
  );
}

/// The motion tokens exposed through the theme.
///
/// ```dart
/// final motion = context.motion;
/// AnimatedOpacity(
///   duration: motion.medium,
///   curve: motion.emphasized,
///   opacity: 1,
///   child: child,
/// );
/// ```
@immutable
final class AppMotionTokens extends ThemeExtension<AppMotionTokens> {
  /// Creates a motion token set. The defaults follow Material 3 Expressive.
  const new({
    this.short = AppDurations.short,
    this.medium = AppDurations.medium,
    this.long = AppDurations.long,
    this.extraLong = AppDurations.extraLong,
    this.stagger = AppDurations.stagger,
    this.emphasized = AppCurves.emphasized,
    this.emphasizedDecelerate = AppCurves.emphasizedDecelerate,
    this.emphasizedAccelerate = AppCurves.emphasizedAccelerate,
    this.standard = AppCurves.standard,
    this.pressSpring = AppSprings.press,
    this.bounceSpring = AppSprings.bounce,
  });

  /// The default token set used when no theme extension is installed.
  static const AppMotionTokens standardTokens = AppMotionTokens();

  /// Duration for small state changes.
  final Duration short;

  /// Duration for standard transitions.
  final Duration medium;

  /// Duration for large transitions.
  final Duration long;

  /// Duration for elaborate choreography.
  final Duration extraLong;

  /// Delay between consecutive staggered children.
  final Duration stagger;

  /// The prominent emphasized curve.
  final Curve emphasized;

  /// Decelerating emphasized curve.
  final Curve emphasizedDecelerate;

  /// Accelerating emphasized curve.
  final Curve emphasizedAccelerate;

  /// Standard utility curve.
  final Curve standard;

  /// Spring used for press feedback.
  final SpringDescription pressSpring;

  /// Spring with a playful overshoot.
  final SpringDescription bounceSpring;

  /// Reads the tokens from [context], falling back to the defaults.
  static AppMotionTokens of(BuildContext context) =>
      Theme.of(context).extension<AppMotionTokens>() ?? standardTokens;

  /// Reads the tokens and collapses every duration to zero when the platform
  /// asks for reduced motion (`MediaQuery.disableAnimations`).
  static AppMotionTokens resolve(BuildContext context) {
    final tokens = of(context);
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!disableAnimations) {
      return tokens;
    }
    return tokens.copyWith(
      short: AppDurations.instant,
      medium: AppDurations.instant,
      long: AppDurations.instant,
      extraLong: AppDurations.instant,
      stagger: AppDurations.instant,
    );
  }

  @override
  AppMotionTokens copyWith({
    Duration? short,
    Duration? medium,
    Duration? long,
    Duration? extraLong,
    Duration? stagger,
    Curve? emphasized,
    Curve? emphasizedDecelerate,
    Curve? emphasizedAccelerate,
    Curve? standard,
    SpringDescription? pressSpring,
    SpringDescription? bounceSpring,
  }) {
    return AppMotionTokens(
      short: short ?? this.short,
      medium: medium ?? this.medium,
      long: long ?? this.long,
      extraLong: extraLong ?? this.extraLong,
      stagger: stagger ?? this.stagger,
      emphasized: emphasized ?? this.emphasized,
      emphasizedDecelerate: emphasizedDecelerate ?? this.emphasizedDecelerate,
      emphasizedAccelerate: emphasizedAccelerate ?? this.emphasizedAccelerate,
      standard: standard ?? this.standard,
      pressSpring: pressSpring ?? this.pressSpring,
      bounceSpring: bounceSpring ?? this.bounceSpring,
    );
  }

  @override
  AppMotionTokens lerp(
    covariant ThemeExtension<AppMotionTokens>? other,
    double t,
  ) {
    if (other is! AppMotionTokens) {
      return this;
    }
    return AppMotionTokens(
      short: _lerpDuration(short, other.short, t),
      medium: _lerpDuration(medium, other.medium, t),
      long: _lerpDuration(long, other.long, t),
      extraLong: _lerpDuration(extraLong, other.extraLong, t),
      stagger: _lerpDuration(stagger, other.stagger, t),
      emphasized: t < 0.5 ? emphasized : other.emphasized,
      emphasizedDecelerate: t < 0.5
          ? emphasizedDecelerate
          : other.emphasizedDecelerate,
      emphasizedAccelerate: t < 0.5
          ? emphasizedAccelerate
          : other.emphasizedAccelerate,
      standard: t < 0.5 ? standard : other.standard,
      pressSpring: t < 0.5 ? pressSpring : other.pressSpring,
      bounceSpring: t < 0.5 ? bounceSpring : other.bounceSpring,
    );
  }

  static Duration _lerpDuration(Duration a, Duration b, double t) {
    final micros = a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t;
    return Duration(microseconds: micros.round());
  }
}
