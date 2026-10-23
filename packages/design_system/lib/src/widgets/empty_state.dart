import 'package:design_system/src/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// A centered illustration, title, message, and optional call to action shown
/// when a collection has no content.
class EmptyState extends StatelessWidget {
  /// Creates an empty state.
  const new({
    required this.title,
    super.key,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  /// The primary message.
  final String title;

  /// Optional supporting text.
  final String? message;

  /// The illustration icon.
  final IconData icon;

  /// An optional action shown below the message.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colors.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              style: context.text.emphasisMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: context.text.scale.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}
