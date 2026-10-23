import 'package:design_system/src/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// A themed list row with an optional leading icon and trailing widget.
class AppListTile extends StatelessWidget {
  /// Creates a list tile.
  const new({
    required this.title,
    super.key,
    this.subtitle,
    this.leadingIcon,
    this.trailing,
    this.onTap,
    this.dense = false,
  });

  /// The primary label.
  final String title;

  /// Optional supporting text below [title].
  final String? subtitle;

  /// An optional leading icon.
  final IconData? leadingIcon;

  /// An optional trailing widget, for example a chevron or a switch.
  final Widget? trailing;

  /// Called when the tile is tapped.
  final VoidCallback? onTap;

  /// Whether the tile uses a compact height.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: dense,
      leading: leadingIcon == null ? null : Icon(leadingIcon),
      title: Text(title, style: context.text.emphasisSmall),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: context.text.scale.bodySmall),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
