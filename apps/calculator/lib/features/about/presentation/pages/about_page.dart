import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Static information about the calculator: what it is, how it is built, and
/// the keyboard shortcuts it understands.
class AboutPage extends StatelessWidget {
  /// Creates the page.
  const new({super.key});

  /// The displayed version. Keep in sync with `pubspec.yaml`.
  static const String version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppScaffold(
      title: 'About',
      leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
      body: ListView(
        key: const Key('about-list'),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calculate_outlined,
                    size: 40,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Calculator', style: context.text.emphasisLarge),
                const SizedBox(height: 4),
                Text(
                  'Version $version',
                  style: context.text.scale.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A Material 3 Expressive expression calculator for Linux, '
                  'built on the shared workspace.',
                  textAlign: TextAlign.center,
                  style: context.text.scale.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Under the hood', style: context.text.emphasisMedium),
                const SizedBox(height: 12),
                const _FeatureRow(
                  icon: Icons.functions,
                  title: 'Dependency-free math',
                  message:
                      'The tokenizer, parser, and evaluator live in core, so '
                      'the same engine is unit tested without Flutter.',
                ),
                const _FeatureRow(
                  icon: Icons.palette_outlined,
                  title: 'Shared design system',
                  message:
                      'Colors, type, shapes, and motion all come from '
                      'design_system; the app hardcodes none of them.',
                ),
                const _FeatureRow(
                  icon: Icons.storage_outlined,
                  title: 'Local history',
                  message:
                      'The last 20 calculations stay on this device in the '
                      'workspace key/value store.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Keyboard', style: context.text.emphasisMedium),
                const SizedBox(height: 12),
                const _ShortcutRow(keys: 'Enter =', action: 'Evaluate'),
                const _ShortcutRow(keys: 'Backspace', action: 'Delete a key'),
                const _ShortcutRow(keys: 'Esc', action: 'Clear the expression'),
                const _ShortcutRow(
                  keys: '0-9 . + - * / % ^ ( )',
                  action: 'Type an expression',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: EdgeInsets.zero,
            child: AppListTile(
              title: 'Open-source licenses',
              subtitle: 'Packages bundled with this app',
              leadingIcon: Icons.description_outlined,
              trailing: const Icon(Icons.open_in_new),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Calculator',
                applicationVersion: version,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const new({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.emphasisSmall),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: context.text.scale.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const new({required this.keys, required this.action});

  final String keys;
  final String action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(context.shapes.extraSmall),
            ),
            child: Text(keys, style: context.text.scale.labelMedium),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              action,
              style: context.text.scale.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
