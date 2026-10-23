import 'package:design_system/src/motion/animated_pressable.dart';
import 'package:design_system/src/motion/animated_theme_switcher.dart';
import 'package:design_system/src/motion/fade_slide_in.dart';
import 'package:design_system/src/motion/staggered_list.dart';
import 'package:design_system/src/theme/app_theme.dart';
import 'package:design_system/src/theme/color_schemes.dart';
import 'package:design_system/src/theme/theme_extensions.dart';
import 'package:design_system/src/widgets/app_button.dart';
import 'package:design_system/src/widgets/app_card.dart';
import 'package:design_system/src/widgets/app_dialog.dart';
import 'package:design_system/src/widgets/app_list_tile.dart';
import 'package:design_system/src/widgets/app_scaffold.dart';
import 'package:design_system/src/widgets/app_text_field.dart';
import 'package:design_system/src/widgets/empty_state.dart';
import 'package:design_system/src/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';

/// A live, scrollable gallery of every design-system widget and motion token.
///
/// The gallery lives in the design system (not in an app) so every desktop
/// host can render exactly the same demo without duplicating UI code.
/// The hosting app owns the state: it passes the current [themeMode] and
/// [colorVariant] and receives changes through the callbacks.
class DesignSystemGallery extends StatefulWidget {
  /// Creates the gallery.
  const new({
    required this.themeMode,
    required this.onThemeModeChanged,
    super.key,
    this.title = 'Design System',
    this.colorVariant = AppColorVariant.expressive,
    this.onColorVariantChanged,
    this.onOpenDetails,
  });

  /// The app bar title, supplied by the host so it can be localized.
  final String title;

  /// The theme mode selected by the host app.
  final ThemeMode themeMode;

  /// Called when the user picks another theme mode.
  final ValueChanged<ThemeMode> onThemeModeChanged;

  /// The color variant selected by the host app.
  final AppColorVariant colorVariant;

  /// Called when the user cycles to another color variant.
  final ValueChanged<AppColorVariant>? onColorVariantChanged;

  /// Called when the user wants to open the detail page. When `null` the
  /// navigation button is hidden.
  final VoidCallback? onOpenDetails;

  @override
  State<DesignSystemGallery> createState() => _DesignSystemGalleryState();
}

class _DesignSystemGalleryState extends State<DesignSystemGallery> {
  final TextEditingController _nameController = TextEditingController();
  var _pressCount = 0;
  var _notificationsEnabled = true;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showConfirmation() async {
    final confirmed = await AppDialog.show(
      context,
      title: 'Delete workspace?',
      message: 'This removes every package and app in the workspace.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!mounted || confirmed == null) {
      return;
    }
    _showMessage(confirmed ? 'Confirmed' : 'Cancelled');
  }

  void _cycleVariant() {
    final onChange = widget.onColorVariantChanged;
    if (onChange == null) {
      return;
    }
    const variants = AppColorVariant.values;
    final next = variants[(widget.colorVariant.index + 1) % variants.length];
    onChange(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: widget.title,
      actions: [
        IconButton(
          tooltip: 'Toggle light and dark',
          onPressed: () => widget.onThemeModeChanged(
            isDark ? ThemeMode.light : ThemeMode.dark,
          ),
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showConfirmation,
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Dialog'),
      ),
      body: ListView(
        children: [
          FadeSlideIn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Material 3 Expressive', style: text.emphasisLarge),
                const SizedBox(height: 8),
                Text(
                  'One theme, widget, and motion layer shared by every app in '
                  'the workspace. Every value below comes from the theme.',
                  style: text.scale.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _AppearanceCard(
            themeMode: widget.themeMode,
            variant: widget.colorVariant,
            onThemeModeChanged: widget.onThemeModeChanged,
            onCycleVariant: widget.onColorVariantChanged == null
                ? null
                : _cycleVariant,
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Buttons',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppButton(
                  label: 'Filled',
                  onPressed: () => _showMessage('Filled button'),
                ),
                AppButton(
                  label: 'Tonal',
                  variant: AppButtonVariant.tonal,
                  onPressed: () => _showMessage('Tonal button'),
                ),
                AppButton(
                  label: 'Outlined',
                  variant: AppButtonVariant.outlined,
                  onPressed: () => _showMessage('Outlined button'),
                ),
                AppButton(
                  label: 'Text',
                  variant: AppButtonVariant.text,
                  onPressed: () => _showMessage('Text button'),
                ),
                const AppButton(label: 'Disabled'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Inputs',
            child: Column(
              children: [
                AppTextField(
                  controller: _nameController,
                  label: 'Display name',
                  hint: 'Ada Lovelace',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 8),
                AppListTile(
                  title: 'Notifications',
                  subtitle: 'A daily summary of workspace activity',
                  leadingIcon: Icons.notifications_outlined,
                  trailing: Switch.adaptive(
                    value: _notificationsEnabled,
                    onChanged: (value) =>
                        setState(() => _notificationsEnabled = value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Animated pressable',
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Press and release', style: text.emphasisSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Pressed $_pressCount times',
                        style: text.scale.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedPressable(
                  onTap: () => setState(() => _pressCount++),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.touch_app_outlined,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Staggered list',
            child: StaggeredList(
              scrollable: false,
              itemCount: _staggeredItems.length,
              itemBuilder: (context, index) {
                final item = _staggeredItems[index];
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: AppListTile(
                    title: item.$1,
                    subtitle: item.$2,
                    leadingIcon: item.$3,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showMessage(item.$1),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Loading and empty states',
            child: Column(
              children: [
                const AppLoadingIndicator(value: 0.65, label: 'Syncing 65%'),
                const SizedBox(height: 24),
                EmptyState(
                  title: 'Nothing here yet',
                  message: 'Empty states keep short collections friendly.',
                  action: AppButton(
                    label: 'Create item',
                    variant: AppButtonVariant.tonal,
                    onPressed: () => _showMessage('Create item'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Theme preview',
            child: AnimatedThemeSwitcher(
              data: isDark
                  ? AppTheme.light(
                      variant: widget.colorVariant,
                      highContrast: context.highContrast,
                    )
                  : AppTheme.dark(
                      variant: widget.colorVariant,
                      highContrast: context.highContrast,
                    ),
              child: Builder(
                builder: (context) {
                  final previewColors = context.colors;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: previewColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(context.shapes.large),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDark ? 'Light theme preview' : 'Dark theme preview',
                          style: context.text.emphasisMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            FilledButton(
                              onPressed: () {},
                              child: const Text('Primary'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {},
                              child: const Text('Secondary'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.onOpenDetails != null)
            AppButton(
              label: 'Open detail page',
              icon: Icons.arrow_forward,
              expand: true,
              onPressed: widget.onOpenDetails,
            ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Every component above is exported by design_system',
              style: text.scale.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

const List<(String, String, IconData)> _staggeredItems = [
  ('Motion tokens', 'Durations, curves, and springs', Icons.speed_outlined),
  (
    'Color variants',
    'Seven expressive dynamic schemes',
    Icons.palette_outlined,
  ),
  ('Typography', 'Full M3 scale plus emphasis', Icons.text_fields_outlined),
  ('Shapes', 'Extra small through extra large', Icons.rounded_corner_outlined),
  (
    'Accessibility',
    'Reduced motion and high contrast',
    Icons.accessibility_new,
  ),
];

class _AppearanceCard extends StatelessWidget {
  const new({
    required this.themeMode,
    required this.variant,
    required this.onThemeModeChanged,
    required this.onCycleVariant,
  });

  final ThemeMode themeMode;
  final AppColorVariant variant;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback? onCycleVariant;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Appearance', style: context.text.emphasisMedium),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_outlined),
                label: Text('System'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text('Light'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text('Dark'),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (selection) =>
                onThemeModeChanged(selection.first),
          ),
          const SizedBox(height: 12),
          AppListTile(
            title: 'Color variant',
            subtitle: variant.label,
            leadingIcon: Icons.palette_outlined,
            trailing: onCycleVariant == null
                ? null
                : IconButton(
                    tooltip: 'Next color variant',
                    onPressed: onCycleVariant,
                    icon: const Icon(Icons.chevron_right),
                  ),
            onTap: onCycleVariant,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const new({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.emphasisMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
