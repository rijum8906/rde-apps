import 'package:calculator/features/calculator/presentation/widgets/calculator_button.dart';
import 'package:calculator/features/calculator/presentation/widgets/deg_rad_toggle.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Secondary scientific functions for the calculator.
class ScientificPanel extends StatelessWidget {
  const new({
    required this.second,
    required this.angleMode,
    required this.onSecondChanged,
    required this.onAngleModeChanged,
    required this.onToken,
    super.key,
  });

  final bool second;
  final AngleMode angleMode;
  final ValueChanged<bool> onSecondChanged;
  final ValueChanged<AngleMode> onAngleModeChanged;
  final ValueChanged<String> onToken;

  @override
  Widget build(BuildContext context) {
    final motion = AppMotionTokens.resolve(context);
    final trig = second
        ? const [
            ('asin', 'arc sine'),
            ('acos', 'arc cosine'),
            ('atan', 'arc tangent'),
          ]
        : const [('sin', 'sine'), ('cos', 'cosine'), ('tan', 'tangent')];
    final functions = <(String, String, String)>[
      ('2nd', 'second functions', '2nd'),
      (trig[0].$1, trig[0].$2, '${trig[0].$1}('),
      (trig[1].$1, trig[1].$2, '${trig[1].$1}('),
      (trig[2].$1, trig[2].$2, '${trig[2].$1}('),
      ('ln', 'natural logarithm', 'ln('),
      ('log', 'base ten logarithm', 'log('),
      ('√', 'square root', 'sqrt('),
      ('x²', 'square', '^2'),
      ('xʸ', 'power', '^'),
      ('π', 'pi', 'pi'),
      ('e', 'e', 'e'),
      ('!', 'factorial', '!'),
      ('%', 'percent', '%'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: DegRadToggle(
                mode: angleMode,
                onChanged: onAngleModeChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: functions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.9,
          ),
          itemBuilder: (context, index) {
            final item = functions[index];
            if (item.$1 == '2nd') {
              return Semantics(
                label: item.$2,
                toggled: second,
                child: AnimatedSwitcher(
                  duration: motion.short,
                  child: CalculatorButton(
                    key: ValueKey('second-$second'),
                    label: item.$3,
                    semanticsLabel: item.$2,
                    style: CalculatorButtonStyle.function,
                    onPressed: () => onSecondChanged(!second),
                  ),
                ),
              );
            }
            return CalculatorButton(
              label: item.$1,
              semanticsLabel: item.$2,
              style: CalculatorButtonStyle.function,
              onPressed: () => onToken(item.$3),
            );
          },
        ),
      ],
    );
  }
}
