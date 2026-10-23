import 'package:design_system/src/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// A spinner with an optional label.
///
/// When the platform requests reduced motion, an indeterminate spinner is
/// replaced by a static hourglass so no animation runs.
class AppLoadingIndicator extends StatelessWidget {
  /// Creates a loading indicator.
  const new({super.key, this.label, this.value, this.size = 32});

  /// Optional text shown below the spinner.
  final String? label;

  /// Progress from 0 to 1 for a determinate indicator; `null` spins endlessly.
  final double? value;

  /// The diameter of the spinner.
  final double size;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final isIndeterminate = value == null;
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: reduceMotion && isIndeterminate
              ? Icon(
                  Icons.hourglass_bottom,
                  size: size,
                  color: colors.onSurfaceVariant,
                )
              : CircularProgressIndicator(value: value, strokeWidth: 3),
        ),
        if (label != null) ...[
          const SizedBox(height: 12),
          Text(
            label!,
            style: context.text.scale.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
