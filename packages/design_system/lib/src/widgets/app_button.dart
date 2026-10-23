import 'package:flutter/material.dart';

/// The visual emphasis of an [AppButton].
enum AppButtonVariant {
  /// High-emphasis filled button.
  filled,

  /// Medium-emphasis tonal button.
  tonal,

  /// Low-emphasis outlined button.
  outlined,

  /// Lowest-emphasis text button.
  text,
}

/// A themed button that maps [AppButtonVariant] onto the Material 3 button
/// families, with an optional leading icon.
class AppButton extends StatelessWidget {
  /// Creates a button.
  const new({
    required this.label,
    super.key,
    this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.icon,
    this.expand = false,
  });

  /// The visible label.
  final String label;

  /// Called when the button is tapped. `null` disables the button.
  final VoidCallback? onPressed;

  /// The visual emphasis of the button.
  final AppButtonVariant variant;

  /// An optional icon shown before the label.
  final IconData? icon;

  /// Whether the button should stretch to the available width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = _buildChild(context);
    final button = switch (variant) {
      AppButtonVariant.filled => FilledButton(
        onPressed: onPressed,
        child: child,
      ),
      AppButtonVariant.tonal => FilledButton.tonal(
        onPressed: onPressed,
        child: child,
      ),
      AppButtonVariant.outlined => OutlinedButton(
        onPressed: onPressed,
        child: child,
      ),
      AppButtonVariant.text => TextButton(onPressed: onPressed, child: child),
    };

    if (!expand) {
      return button;
    }
    return SizedBox(width: double.infinity, child: button);
  }

  Widget _buildChild(BuildContext context) {
    if (icon == null) {
      return Text(label);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Flexible(child: Text(label)),
      ],
    );
  }
}
