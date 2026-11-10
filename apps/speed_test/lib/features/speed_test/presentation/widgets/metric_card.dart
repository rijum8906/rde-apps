import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// One measured value on the results grid.
class MetricCard extends StatelessWidget {
  /// Creates a metric card.
  const new({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    super.key,
  });

  /// The metric name, for example `Download`.
  final String label;

  /// The formatted number, or an em dash when nothing has been measured.
  final String value;

  /// The unit shown smaller next to [value]. Empty for count-like metrics.
  final String unit;

  /// The icon identifying the metric.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.scale.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  key: ValueKey('metric-$label'),
                  style: context.text.scale.headlineSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: context.text.scale.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
