import 'package:design_system/src/theme/motion.dart';
import 'package:flutter/material.dart';

/// Reveals a list of children one after another.
///
/// A single [AnimationController] drives every child, staggered by
/// [AppMotionTokens.stagger], so the whole list costs one ticker. Set
/// [scrollable] to `false` to embed the list inside another scroll view.
///
/// When reduced motion is requested, all children are shown immediately.
class StaggeredList extends StatefulWidget {
  /// Creates a staggered list.
  const new({
    required this.itemCount,
    required this.itemBuilder,
    super.key,
    this.spacing = 12,
    this.padding,
    this.scrollable = true,
  });

  /// The number of children to build.
  final int itemCount;

  /// Builds the child at a given index.
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// The gap between two children.
  final double spacing;

  /// Padding around the list.
  final EdgeInsetsGeometry? padding;

  /// Whether the list owns a [ScrollView]. When `false` a [Column] is used.
  final bool scrollable;

  @override
  State<StaggeredList> createState() => _StaggeredListState();
}

class _StaggeredListState extends State<StaggeredList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 0,
  );

  AppMotionTokens _motion = AppMotionTokens.standardTokens;
  Duration _duration = AppDurations.long;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = AppMotionTokens.resolve(context);
    _configure();
  }

  @override
  void didUpdateWidget(covariant StaggeredList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount) {
      _configure();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _configure() {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion || widget.itemCount == 0) {
      _controller
        ..stop()
        ..value = 1;
      return;
    }

    final duration = _motion.long + _motion.stagger * (widget.itemCount - 1);
    if (duration == _duration && _controller.value > 0) {
      return;
    }
    _duration = duration;
    _controller
      ..duration = duration
      ..forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) {
      return const SizedBox.shrink();
    }

    Widget itemAt(int index) {
      return _StaggeredItem(
        index: index,
        animation: _controller,
        duration: _duration,
        stagger: _motion.stagger,
        curve: _motion.emphasizedDecelerate,
        child: widget.itemBuilder(context, index),
      );
    }

    if (!widget.scrollable) {
      return Padding(
        padding: widget.padding ?? EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < widget.itemCount; index++) ...[
              if (index > 0) SizedBox(height: widget.spacing),
              itemAt(index),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      padding: widget.padding,
      itemCount: widget.itemCount,
      separatorBuilder: (_, _) => SizedBox(height: widget.spacing),
      itemBuilder: (_, index) => itemAt(index),
    );
  }
}

class _StaggeredItem extends StatelessWidget {
  const new({
    required this.index,
    required this.animation,
    required this.duration,
    required this.stagger,
    required this.curve,
    required this.child,
  });

  final int index;
  final Animation<double> animation;
  final Duration duration;
  final Duration stagger;
  final Curve curve;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final total = duration.inMicroseconds;
    final start = total == 0
        ? 0.0
        : (index * stagger.inMicroseconds / total).clamp(0.0, 0.9);
    final end = (start + 0.55).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final span = end - start;
        final progress = span <= 0
            ? 1.0
            : ((animation.value - start) / span).clamp(0.0, 1.0);
        final eased = curve.transform(progress);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - eased)),
            child: child,
          ),
        );
      },
    );
  }
}
