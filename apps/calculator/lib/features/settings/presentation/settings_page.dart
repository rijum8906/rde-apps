import 'package:app_routing/app_routing.dart';
import 'package:calculator/features/calculator/presentation/widgets/deg_rad_toggle.dart';
import 'package:calculator/features/settings/domain/app_settings.dart';
import 'package:calculator/features/settings/presentation/settings_cubit.dart';
import 'package:calculator/routing/calculator_routes.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The preferences page: theme, color style, angle unit, and the about entry.
class SettingsPage extends StatelessWidget {
  /// Creates the page.
  const new({super.key});

  /// Swatches shown next to each color style, built once per variant.
  static final Map<AppColorVariant, Color> _swatches = {
    for (final variant in AppColorVariant.values)
      variant: AppColorSchemes.light(variant: variant).primary,
  };

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;
    final cubit = context.read<SettingsCubit>();

    return AppScaffold(
      title: 'Settings',
      body: ListView(
        key: const Key('settings-list'),
        children: [
          _SettingsSection(
            title: 'Appearance',
            description: 'Changes apply to every page immediately.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: context.text.emphasisSmall),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                    ),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (selection) =>
                      cubit.setThemeMode(selection.first),
                ),
                const SizedBox(height: 20),
                Text('Color style', style: context.text.emphasisSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final variant in AppColorVariant.values)
                      ChoiceChip(
                        key: ValueKey('color-${variant.name}'),
                        avatar: CircleAvatar(
                          backgroundColor: _swatches[variant],
                          radius: 7,
                        ),
                        label: Text(variant.label),
                        selected: settings.colorVariant == variant,
                        onSelected: (_) => cubit.setColorVariant(variant),
                      ),
                  ],
                ),
              ],
            ),
          ),
          _SettingsSection(
            title: 'Calculation',
            description: 'The unit used by trigonometry and its inverses.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppListTile(
                  title: 'Angle unit',
                  subtitle: settings.angleMode == AngleMode.degrees
                      ? 'Degrees, 0° to 360°'
                      : 'Radians, 0 to 2π',
                  leadingIcon: Icons.straighten,
                ),
                const SizedBox(height: 8),
                DegRadToggle(
                  mode: settings.angleMode,
                  onChanged: cubit.setAngleMode,
                ),
              ],
            ),
          ),
          _SettingsSection(
            title: 'About',
            child: AppListTile(
              title: 'About Calculator',
              subtitle: 'Version, keyboard shortcuts, and licenses',
              leadingIcon: Icons.info_outline,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.pushRoute(CalculatorRoutes.about),
            ),
          ),
          AppButton(
            label: 'Restore defaults',
            icon: Icons.restart_alt,
            variant: AppButtonVariant.outlined,
            expand: true,
            onPressed: settings == AppSettings.defaults
                ? null
                : () => _restoreDefaults(context, cubit),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _restoreDefaults(
    BuildContext context,
    SettingsCubit cubit,
  ) async {
    final confirmed = await AppDialog.show(
      context,
      title: 'Restore defaults?',
      message:
          'Theme, color style, and angle unit return to their defaults. '
          'Your history is kept.',
      confirmLabel: 'Restore',
    );
    if (!(confirmed ?? false)) {
      return;
    }
    await cubit.restoreDefaults();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Preferences restored')));
  }
}

class _SettingsSection extends StatelessWidget {
  const new({required this.title, required this.child, this.description});

  final String title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.text.emphasisMedium),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description!,
                style: context.text.scale.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
