import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Small segmented selector for trigonometric units.
class DegRadToggle extends StatelessWidget {
  const new({required this.mode, required this.onChanged, super.key});
  final AngleMode mode;
  final ValueChanged<AngleMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final motion = AppMotionTokens.resolve(context);
    return SegmentedButton<AngleMode>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: AngleMode.degrees, label: Text('DEG')),
        ButtonSegment(value: AngleMode.radians, label: Text('RAD')),
      ],
      selected: {mode},
      style: ButtonStyle(animationDuration: motion.short),
      onSelectionChanged: (value) => onChanged(value.first),
    );
  }
}
