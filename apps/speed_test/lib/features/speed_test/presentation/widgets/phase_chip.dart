import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The visual state of one test phase.
enum PhaseStatus {
  /// Not reached yet.
  pending,

  /// Currently measuring.
  active,

  /// Finished successfully.
  done,
}

/// A compact chip showing one phase of the test and whether it is done.
class PhaseChip extends StatelessWidget {
  /// Creates a phase chip.
  const new({
    required this.label,
    required this.icon,
    required this.status,
    super.key,
  });

  /// The phase name.
  final String label;

  /// The icon shown before the name.
  final IconData icon;

  /// Whether the phase is pending, active, or done.
  final PhaseStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final background = switch (status) {
      PhaseStatus.pending => colors.surfaceContainerHighest,
      PhaseStatus.active => colors.primaryContainer,
      PhaseStatus.done => colors.secondaryContainer,
    };
    final foreground = switch (status) {
      PhaseStatus.pending => colors.onSurfaceVariant,
      PhaseStatus.active => colors.onPrimaryContainer,
      PhaseStatus.done => colors.onSecondaryContainer,
    };

    return AnimatedContainer(
      duration: context.motion.medium,
      curve: context.motion.emphasized,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(context.shapes.extraSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == PhaseStatus.done ? Icons.check : icon,
            size: 16,
            color: foreground,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: context.text.scale.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
