import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:speed_test/features/speed_test/presentation/model/speed_meter_model.dart';

/// A 270° speed dial with an animated arc and a live numeric readout.
///
/// The widget is presentation-only: the page derives a [SpeedMeterModel] from
/// bloc state. Colors, motion, and shapes all come from `design_system`.
class SpeedMeter extends StatefulWidget {
  /// Creates the meter.
  const new({required this.model, super.key});

  /// The current value, scale, and caption.
  final SpeedMeterModel model;

  @override
  State<SpeedMeter> createState() => _SpeedMeterState();
}

class _SpeedMeterState extends State<SpeedMeter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _fraction;
  double _target = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _target = widget.model.fraction;
    _fraction = AlwaysStoppedAnimation<double>(_target);
  }

  @override
  void didUpdateWidget(SpeedMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = widget.model.fraction;
    if ((target - _target).abs() < 0.001) {
      return;
    }
    final motion = context.motion;
    final begin = _fraction.value;
    _controller
      ..stop()
      ..duration = motion.short
      ..reset();
    _fraction = Tween<double>(begin: begin, end: target).animate(
      CurvedAnimation(parent: _controller, curve: motion.emphasizedDecelerate),
    );
    _target = target;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final model = widget.model;
    final reading = model.reading;

    return LayoutBuilder(
      builder: (context, constraints) {
        final diameter = math.min<double>(constraints.maxWidth, 420);
        return Center(
          child: SizedBox(
            width: diameter,
            height: diameter,
            child: Semantics(
              label: '${model.label}: ${reading.formatted}',
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _SpeedMeterPainter(
                            fraction: _fraction.value,
                            trackColor: colors.surfaceContainerHighest,
                            tickColor: colors.outlineVariant,
                            gradientColors: [colors.primary, colors.tertiary],
                            dotColor: colors.onPrimary,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(diameter * 0.13),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (model.isRunning) ...[
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: colors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Flexible(
                                  child: Text(
                                    model.label.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.scale.labelLarge?.copyWith(
                                      color: colors.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                reading.formattedValue,
                                key: const Key('speed-meter-value'),
                                style: text.scale.displayLarge?.copyWith(
                                  color: colors.onSurface,
                                  fontSize: diameter * 0.27,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                  letterSpacing: -3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              reading.unit,
                              key: const Key('speed-meter-unit'),
                              style: text.scale.titleMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontSize: diameter * 0.062,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Scale 0 – ${model.scaleLabel}',
                              style: text.scale.labelSmall?.copyWith(
                                color: colors.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SpeedMeterPainter extends CustomPainter {
  const new({
    required this.fraction,
    required this.trackColor,
    required this.tickColor,
    required this.gradientColors,
    required this.dotColor,
  });

  final double fraction;
  final Color trackColor;
  final Color tickColor;
  final List<Color> gradientColors;
  final Color dotColor;

  static const double _startAngle = math.pi * 0.75;
  static const double _sweepAngle = math.pi * 1.5;
  static const int _tickCount = 40;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * 0.055;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - stroke * 0.75;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawArc(rect, _startAngle, _sweepAngle, false, track);

    if (fraction > 0) {
      final progress = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: gradientColors,
        ).createShader(rect);
      canvas.drawArc(
        rect,
        _startAngle,
        _sweepAngle * fraction.clamp(0.0, 1.0),
        false,
        progress,
      );

      final angle = _startAngle + _sweepAngle * fraction.clamp(0.0, 1.0);
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawCircle(point, stroke * 0.52, Paint()..color = dotColor);
    }

    final tickOuter = radius - stroke * 0.85;
    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index <= _tickCount; index++) {
      final major = index % 5 == 0;
      final angle = _startAngle + _sweepAngle * index / _tickCount;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final inner = tickOuter - (major ? 12.0 : 6.0);
      canvas.drawLine(
        center + direction * inner,
        center + direction * tickOuter,
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedMeterPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.tickColor != tickColor ||
      oldDelegate.dotColor != dotColor;
}
