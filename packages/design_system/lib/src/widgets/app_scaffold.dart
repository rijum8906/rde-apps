import 'package:design_system/src/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// A themed page shell with an optional app bar, safe-area handling, and
/// consistent content padding.
class AppScaffold extends StatelessWidget {
  /// Creates a scaffold.
  const new({
    required this.body,
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.appBar,
    this.padding = const EdgeInsets.all(16),
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.endDrawer,
  });

  /// The page content.
  final Widget body;

  /// The app bar title. Ignored when [appBar] is provided.
  final String? title;

  /// Actions shown on the right side of the app bar.
  final List<Widget>? actions;

  /// A custom widget shown before the title.
  final Widget? leading;

  /// A fully custom app bar that replaces the default one.
  final PreferredSizeWidget? appBar;

  /// Padding applied around [body] inside the safe area.
  final EdgeInsetsGeometry padding;

  /// An optional floating action button.
  final Widget? floatingActionButton;

  /// An optional bottom navigation bar.
  final Widget? bottomNavigationBar;

  /// An optional drawer opened from the trailing edge.
  final Widget? endDrawer;

  @override
  Widget build(BuildContext context) {
    final resolvedAppBar =
        appBar ??
        (title == null
            ? null
            : AppBar(
                title: Text(title!, style: context.text.emphasisMedium),
                leading: leading,
                actions: actions,
              ));

    return Scaffold(
      appBar: resolvedAppBar,
      body: SafeArea(
        child: Padding(padding: padding, child: body),
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      endDrawer: endDrawer,
    );
  }
}
