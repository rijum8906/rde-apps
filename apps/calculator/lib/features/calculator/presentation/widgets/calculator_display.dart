import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The large, right-aligned expression and result display.
class CalculatorDisplay extends StatelessWidget {
  const new({
    required this.expression,
    required this.result,
    required this.errorMessage,
    super.key,
  });

  final String expression;
  final String? result;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final motion = AppMotionTokens.resolve(context);
    final text = Theme.of(context).textTheme;
    final effectiveExpression = expression.isEmpty ? '0' : expression;
    final displayValue = result ?? effectiveExpression;
    return Container(
      color: colors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SingleChildScrollView(
            key: const Key('calculator-expression-scroll'),
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                effectiveExpression,
                key: const Key('calculator-expression'),
                style: text.titleMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (errorMessage != null)
            Text(
              errorMessage!,
              key: const Key('calculator-error'),
              textAlign: TextAlign.right,
              style: text.titleMedium?.copyWith(color: colors.error),
            )
          else
            AnimatedSwitcher(
              duration: motion.short,
              switchInCurve: motion.emphasizedDecelerate,
              switchOutCurve: motion.emphasizedAccelerate,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, .08),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: FittedBox(
                key: ValueKey(displayValue),
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  displayValue,
                  key: const Key('calculator-result'),
                  style:
                      (MediaQuery.sizeOf(context).width < 400
                              ? text.displayMedium
                              : text.displayLarge)
                          ?.copyWith(color: colors.onSurface),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
