import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Toggle for the compact scientific keypad.
class ExpandToggle extends StatelessWidget {
  const new({required this.expanded, required this.onChanged, super.key});
  final bool expanded;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final motion = AppMotionTokens.resolve(context);
    return Semantics(
      label: 'Scientific functions',
      button: true,
      toggled: expanded,
      child: IconButton(
        key: const Key('scientific-expand-toggle'),
        tooltip: 'Scientific functions',
        onPressed: () => onChanged(!expanded),
        icon: AnimatedRotation(
          turns: expanded ? .5 : 0,
          duration: motion.medium,
          curve: motion.emphasized,
          child: const Icon(Icons.expand_more),
        ),
      ),
    );
  }
}
