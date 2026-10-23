import 'package:calculator/features/calculator/presentation/widgets/calculator_button.dart';
import 'package:flutter/material.dart';

/// The standard four-column calculator keypad.
class CalculatorKeypad extends StatelessWidget {
  const new({required this.onKeyPressed, super.key});

  final ValueChanged<String> onKeyPressed;

  static const _keys = <_KeySpec>[
    _KeySpec('C', 'clear', CalculatorButtonStyle.destructive),
    _KeySpec('(', 'left parenthesis', CalculatorButtonStyle.operator),
    _KeySpec(')', 'right parenthesis', CalculatorButtonStyle.operator),
    _KeySpec('÷', 'divided by', CalculatorButtonStyle.operator),
    _KeySpec('7', 'seven', CalculatorButtonStyle.number),
    _KeySpec('8', 'eight', CalculatorButtonStyle.number),
    _KeySpec('9', 'nine', CalculatorButtonStyle.number),
    _KeySpec('×', 'times', CalculatorButtonStyle.operator),
    _KeySpec('4', 'four', CalculatorButtonStyle.number),
    _KeySpec('5', 'five', CalculatorButtonStyle.number),
    _KeySpec('6', 'six', CalculatorButtonStyle.number),
    _KeySpec('−', 'minus', CalculatorButtonStyle.operator),
    _KeySpec('1', 'one', CalculatorButtonStyle.number),
    _KeySpec('2', 'two', CalculatorButtonStyle.number),
    _KeySpec('3', 'three', CalculatorButtonStyle.number),
    _KeySpec('+', 'plus', CalculatorButtonStyle.operator),
    _KeySpec('0', 'zero', CalculatorButtonStyle.number),
    _KeySpec('.', 'decimal point', CalculatorButtonStyle.number),
    _KeySpec('⌫', 'backspace', CalculatorButtonStyle.destructive),
    _KeySpec('=', 'equals', CalculatorButtonStyle.equals),
  ];

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _keys.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 4,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.9,
    ),
    itemBuilder: (context, index) {
      final key = _keys[index];
      return CalculatorButton(
        key: ValueKey('calculator-key-${key.label}'),
        label: key.label,
        semanticsLabel: key.semantics,
        style: key.style,
        onPressed: () => onKeyPressed(key.label),
      );
    },
  );
}

class _KeySpec {
  const new(this.label, this.semantics, this.style);
  final String label;
  final String semantics;
  final CalculatorButtonStyle style;
}
