import 'package:flutter/material.dart';

/// A tonal Material 3 Expressive surface with an optional tap handler.
///
/// The card takes its color, tint, shape, and elevation from the theme, so no
/// shadows or colors are hardcoded here.
class AppCard extends StatelessWidget {
  /// Creates a card.
  const new({
    required this.child,
    super.key,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.semanticLabel,
  });

  /// The card content.
  final Widget child;

  /// Called when the card is tapped. When `null` the card is not interactive.
  final VoidCallback? onTap;

  /// Padding around [child].
  final EdgeInsetsGeometry padding;

  /// An optional accessibility label describing the card.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: Card(
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}
