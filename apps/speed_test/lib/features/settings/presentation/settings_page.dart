import 'package:app_routing/app_routing.dart';
import 'package:app_theme/app_theme.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speed_test/features/settings/presentation/settings_cubit.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_profile.dart';
import 'package:speed_test/routing/speed_test_routes.dart';

/// The preferences page: theme, color style, test profile, and about.
///
/// Theme controls talk to the shared [AppThemeController], so a change made
/// here reaches every app through the desktop theme service.
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
    final theme = AppThemeScope.of(context);
    final followsDesktop = theme.palette != null;
    final profile = context.watch<SettingsCubit>().state;
    final cubit = context.read<SettingsCubit>();
    final isDefault =
        theme.settings == AppThemeSettings.defaults &&
        profile == SpeedTestProfile.balanced;

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
                  segments: [
                    // The desktop theme is only light or dark, so "system" is
                    // not offered while it drives the app.
                    if (!followsDesktop)
                      const ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                      ),
                    const ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'),
                    ),
                    const ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {theme.mode},
                  onSelectionChanged: (selection) =>
                      theme.setMode(selection.first),
                ),
                const SizedBox(height: 20),
                if (followsDesktop)
                  Text(
                    'Colors follow the desktop theme.',
                    style: context.text.scale.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  )
                else ...[
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
                          selected: theme.variant == variant,
                          onSelected: (_) => theme.setVariant(variant),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          _SettingsSection(
            title: 'Speed test',
            description:
                'The profile sets how much data each run transfers across '
                'parallel streams.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<SpeedTestProfile>(
                  key: const Key('profile-selector'),
                  showSelectedIcon: false,
                  segments: [
                    for (final value in SpeedTestProfile.values)
                      ButtonSegment(value: value, label: Text(value.label)),
                  ],
                  selected: {profile},
                  onSelectionChanged: (selection) =>
                      cubit.setProfile(selection.first),
                ),
                const SizedBox(height: 12),
                Text(
                  profile.description,
                  style: context.text.scale.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'One run uses about '
                  '${profile.totalMegabytes.toStringAsFixed(0)} MB '
                  '(${profile.downloadMegabytes.toStringAsFixed(0)} MB down, '
                  '${profile.uploadMegabytes.toStringAsFixed(0)} MB up) and '
                  '${profile.latencySamples} latency samples.',
                  style: context.text.scale.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _SettingsSection(
            title: 'About',
            child: AppListTile(
              title: 'About Speed Test',
              subtitle: 'Version, how it measures, and licenses',
              leadingIcon: Icons.info_outline,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.pushRoute(SpeedTestRoutes.about),
            ),
          ),
          AppButton(
            label: 'Restore defaults',
            icon: Icons.restart_alt,
            variant: AppButtonVariant.outlined,
            expand: true,
            onPressed: isDefault
                ? null
                : () => _restoreDefaults(context, theme, cubit),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _restoreDefaults(
    BuildContext context,
    AppThemeController theme,
    SettingsCubit cubit,
  ) async {
    final confirmed = await AppDialog.show(
      context,
      title: 'Restore defaults?',
      message:
          'Theme, color style, and test profile return to their defaults. '
          'Your saved results are kept.',
      confirmLabel: 'Restore',
    );
    if (!(confirmed ?? false)) {
      return;
    }
    await theme.reset();
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
