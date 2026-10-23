import 'package:design_system/src/theme/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Wraps [child] in a press gesture that scales it down and springs back.
///
/// The animation reads its duration, curve, and spring from [AppMotionTokens]
/// and is a no-op when `MediaQuery.disableAnimations` is set.
class AnimatedPressable extends StatefulWidget {
  /// Creates a pressable surface.
  const new({
    required this.child,
    super.key,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
    this.enabled = true,
  });

  /// The content that reacts to presses.
  final Widget child;

  /// Called when the child is tapped.
  final VoidCallback? onTap;

  /// Called when the child is long-pressed.
  final VoidCallback? onLongPress;

  /// The scale applied while the pointer is down.
  final double pressedScale;

  /// Whether taps are handled at all.
  final bool enabled;

  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<AnimatedPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    lowerBound: -0.25,
    value: 0,
  );

  AppMotionTokens _motion = AppMotionTokens.standardTokens;
  bool _reduceMotion = false;

  bool get _interactive =>
      widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = AppMotionTokens.resolve(context);
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion) {
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_interactive || _reduceMotion) {
      return;
    }
    _controller.animateTo(
      1,
      duration: _motion.short,
      curve: _motion.emphasizedAccelerate,
    );
  }

  void _release() {
    if (!_interactive || _reduceMotion) {
      return;
    }
    _controller.animateWith(
      SpringSimulation(_motion.pressSpring, _controller.value, 0, 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled,
      onTap: _interactive ? widget.onTap : null,
      child: MouseRegion(
        cursor: _interactive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTapDown: _interactive ? _handleTapDown : null,
          onTapUp: _interactive ? (_) => _release() : null,
          onTapCancel: _interactive ? _release : null,
          onTap: _interactive ? widget.onTap : null,
          onLongPress: _interactive ? widget.onLongPress : null,
          child: AnimatedBuilder(
            animation: _controller,
            child: widget.child,
            builder: (context, child) {
              final scale = 1 - _controller.value * (1 - widget.pressedScale);
              return Transform.scale(scale: scale, child: child);
            },
          ),
        ),
      ),
    );
  }
}
