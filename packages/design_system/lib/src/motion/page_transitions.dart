import 'package:design_system/src/theme/motion.dart';
import 'package:flutter/material.dart';

/// The page transitions provided by the design system.
enum AppPageTransition {
  /// A shared-axis transition along the horizontal axis.
  sharedAxisX,

  /// A shared-axis transition along the vertical axis.
  sharedAxisY,

  /// A fade-through transition with a subtle scale.
  fadeThrough,
}

/// Material 3 shared-axis and fade-through page transitions.
///
/// The transitions are pure functions so they can be registered with
/// `go_router` (`transitionsBuilder`) or with `PageTransitionsTheme`:
///
/// ```dart
/// CustomTransitionPage(
///   child: page,
///   transitionDuration: AppDurations.long,
///   transitionsBuilder: (context, animation, secondary, child) =>
///       AppPageTransitions.build(
///         animation: animation,
///         child: child,
///         transition: AppPageTransition.sharedAxisX,
///       ),
/// );
/// ```
abstract final class AppPageTransitions {
  /// The duration of an entering page.
  static const Duration duration = AppDurations.long;

  /// The duration of a leaving page.
  static const Duration reverseDuration = AppDurations.medium;

  /// Builds the transition for [transition] around [child].
  ///
  /// When [disableAnimations] is `true` (or the surrounding media query asks
  /// for reduced motion) the child is returned untouched.
  static Widget build({
    required Animation<double> animation,
    required Widget child,
    AppPageTransition transition = AppPageTransition.sharedAxisX,
    bool disableAnimations = false,
  }) {
    if (disableAnimations) {
      return child;
    }

    final curved = CurvedAnimation(
      parent: animation,
      curve: AppCurves.emphasizedDecelerate,
      reverseCurve: AppCurves.emphasizedAccelerate,
    );

    return switch (transition) {
      AppPageTransition.sharedAxisX => FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      ),
      AppPageTransition.sharedAxisY => FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      ),
      AppPageTransition.fadeThrough => FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(0.3, 1, curve: AppCurves.emphasizedDecelerate),
        ),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          child: child,
        ),
      ),
    };
  }

  /// Returns a [PageTransitionsBuilder] for [transition].
  static PageTransitionsBuilder builder(AppPageTransition transition) {
    return switch (transition) {
      AppPageTransition.sharedAxisX =>
        const SharedAxisXPageTransitionsBuilder(),
      AppPageTransition.sharedAxisY =>
        const SharedAxisYPageTransitionsBuilder(),
      AppPageTransition.fadeThrough =>
        const FadeThroughPageTransitionsBuilder(),
    };
  }
}

/// Registers [AppPageTransition.sharedAxisX] with [PageTransitionsTheme].
final class SharedAxisXPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Creates the builder.
  const new();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AppPageTransitions.build(
      animation: animation,
      child: child,
      disableAnimations:
          MediaQuery.maybeOf(context)?.disableAnimations ?? false,
    );
  }
}

/// Registers [AppPageTransition.sharedAxisY] with [PageTransitionsTheme].
final class SharedAxisYPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Creates the builder.
  const new();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AppPageTransitions.build(
      animation: animation,
      child: child,
      transition: AppPageTransition.sharedAxisY,
      disableAnimations:
          MediaQuery.maybeOf(context)?.disableAnimations ?? false,
    );
  }
}

/// Registers [AppPageTransition.fadeThrough] with [PageTransitionsTheme].
final class FadeThroughPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Creates the builder.
  const new();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AppPageTransitions.build(
      animation: animation,
      child: child,
      transition: AppPageTransition.fadeThrough,
      disableAnimations:
          MediaQuery.maybeOf(context)?.disableAnimations ?? false,
    );
  }
}
