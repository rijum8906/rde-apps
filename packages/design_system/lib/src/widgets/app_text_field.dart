import 'package:flutter/material.dart';

/// A themed single- or multi-line text input.
///
/// Borders, colors, padding, and label styles all come from
/// `ThemeData.inputDecorationTheme`.
class AppTextField extends StatelessWidget {
  /// Creates a text field.
  const new({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.maxLines = 1,
    this.autofocus = false,
  });

  /// Controls the text being edited.
  final TextEditingController? controller;

  /// A floating label shown inside the field.
  final String? label;

  /// Placeholder text shown when the field is empty.
  final String? hint;

  /// An icon shown before the input.
  final IconData? prefixIcon;

  /// An icon shown after the input.
  final IconData? suffixIcon;

  /// Whether the text should be hidden, as for passwords.
  final bool obscureText;

  /// The keyboard type used to edit the text.
  final TextInputType? keyboardType;

  /// The action button shown on the software keyboard.
  final TextInputAction? textInputAction;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the field.
  final ValueChanged<String>? onSubmitted;

  /// Whether the field accepts input.
  final bool enabled;

  /// The maximum number of lines; `null` grows without bound.
  final int? maxLines;

  /// Whether the field requests focus when first shown.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      maxLines: maxLines,
      autofocus: autofocus,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        suffixIcon: suffixIcon == null ? null : Icon(suffixIcon),
      ),
    );
  }
}
