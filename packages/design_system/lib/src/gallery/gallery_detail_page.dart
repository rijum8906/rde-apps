import 'package:design_system/src/motion/fade_slide_in.dart';
import 'package:design_system/src/theme/theme_extensions.dart';
import 'package:design_system/src/widgets/app_button.dart';
import 'package:design_system/src/widgets/app_card.dart';
import 'package:design_system/src/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';

/// A second page used by the hosts to demonstrate page transitions.
///
/// It doubles as a typography and shape specimen.
class GalleryDetailPage extends StatelessWidget {
  /// Creates the detail page.
  const new({super.key, this.title = 'Type & shapes'});

  /// The app bar title, supplied by the host so it can be localized.
  final String title;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final colors = context.colors;

    return AppScaffold(
      title: title,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back),
      ),
      body: ListView(
        children: [
          FadeSlideIn(child: Text('The type scale', style: text.emphasisLarge)),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TypeRow(label: 'displayLarge', style: text.scale.displayLarge),
                _TypeRow(
                  label: 'headlineMedium',
                  style: text.scale.headlineMedium,
                ),
                _TypeRow(label: 'titleLarge', style: text.scale.titleLarge),
                _TypeRow(label: 'bodyLarge', style: text.scale.bodyLarge),
                _TypeRow(label: 'labelLarge', style: text.scale.labelLarge),
                const Divider(height: 32),
                _TypeRow(label: 'emphasisLarge', style: text.emphasisLarge),
                _TypeRow(label: 'emphasisMedium', style: text.emphasisMedium),
                _TypeRow(label: 'emphasisSmall', style: text.emphasisSmall),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shape scale', style: text.emphasisMedium),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _ShapeSwatch(radius: context.shapes.extraSmall),
                    _ShapeSwatch(radius: context.shapes.small),
                    _ShapeSwatch(radius: context.shapes.medium),
                    _ShapeSwatch(radius: context.shapes.large),
                    _ShapeSwatch(radius: context.shapes.extraLarge),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'extraSmall · small · medium · large · extraLarge',
                  style: text.scale.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Back to gallery',
            variant: AppButtonVariant.tonal,
            expand: true,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  const new({required this.label, required this.style});

  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.text.scale.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          Text(label, style: style),
        ],
      ),
    );
  }
}

class _ShapeSwatch extends StatelessWidget {
  const new({required this.radius});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: context.colors.secondaryContainer,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
