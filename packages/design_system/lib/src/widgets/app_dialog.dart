import 'package:design_system/src/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// A themed confirmation dialog with cancel and confirm actions.
///
/// ```dart
/// final confirmed = await AppDialog.show(
///   context,
///   title: 'Delete project?',
///   message: 'This cannot be undone.',
///   destructive: true,
/// );
/// ```
class AppDialog extends StatelessWidget {
  /// Creates a dialog.
  const new({
    required this.title,
    required this.message,
    super.key,
    this.confirmLabel = 'Continue',
    this.cancelLabel = 'Cancel',
    this.destructive = false,
  });

  /// The dialog title.
  final String title;

  /// The supporting message.
  final String message;

  /// The label of the confirming action.
  final String confirmLabel;

  /// The label of the dismissing action.
  final String cancelLabel;

  /// Whether the confirm action uses the error color.
  final bool destructive;

  /// Shows the dialog and resolves to `true` when confirmed.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Continue',
    String cancelLabel = 'Cancel',
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AppDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: colors.onError,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
