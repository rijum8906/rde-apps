import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Visual roles for calculator keys.
enum CalculatorButtonStyle { number, operator, equals, function, destructive }

/// A themed, accessible calculator key with shared press feedback.
class CalculatorButton extends StatelessWidget {
  const new({
    required this.label,
    required this.semanticsLabel,
    required this.style,
    required this.onPressed,
    super.key,
  });

  final String label;
  final String semanticsLabel;
  final CalculatorButtonStyle style;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final shapes = AppShapes.of(context);
    final isFunction = style == CalculatorButtonStyle.function;
    final palette = switch (style) {
      CalculatorButtonStyle.number => (
        colors.surfaceContainerHighest,
        colors.onSurface,
      ),
      CalculatorButtonStyle.operator => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      CalculatorButtonStyle.equals => (colors.primary, colors.onPrimary),
      CalculatorButtonStyle.function => (
        colors.surfaceContainer,
        colors.onSurfaceVariant,
      ),
      CalculatorButtonStyle.destructive => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
      ),
    };
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: AnimatedPressable(
        onTap: onPressed,
        child: Material(
          color: palette.$1,
          shape: isFunction ? shapes.largeShape : shapes.extraLargeShape,
          child: InkWell(
            onTap: onPressed,
            customBorder: isFunction
                ? shapes.largeShape
                : shapes.extraLargeShape,
            child: Center(
              child: Text(
                label,
                style:
                    (isFunction
                            ? Theme.of(context).textTheme.titleMedium
                            : Theme.of(context).textTheme.headlineSmall)
                        ?.copyWith(color: palette.$2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
