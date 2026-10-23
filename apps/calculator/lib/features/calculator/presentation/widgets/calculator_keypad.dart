import 'package:calculator/features/calculator/presentation/widgets/calculator_button.dart';
import 'package:flutter/material.dart';

/// The standard four-column calculator keypad.
///
/// The keypad fills the height it is given, so keys stay proportional on any
/// window size instead of overflowing a fixed grid.
class CalculatorKeypad extends StatelessWidget {
  /// Creates the keypad.
  const new({required this.onKeyPressed, super.key});

  /// Called with the raw token of the key that was pressed.
  final ValueChanged<String> onKeyPressed;

  /// The tallest the keypad grows on large windows.
  static const double maxHeight = 420;

  static const _rows = <List<_KeySpec>>[
    [
      _KeySpec('C', 'clear', CalculatorButtonStyle.destructive),
      _KeySpec('(', 'left parenthesis', CalculatorButtonStyle.operator),
      _KeySpec(')', 'right parenthesis', CalculatorButtonStyle.operator),
      _KeySpec('÷', 'divided by', CalculatorButtonStyle.operator),
    ],
    [
      _KeySpec('7', 'seven', CalculatorButtonStyle.number),
      _KeySpec('8', 'eight', CalculatorButtonStyle.number),
      _KeySpec('9', 'nine', CalculatorButtonStyle.number),
      _KeySpec('×', 'times', CalculatorButtonStyle.operator),
    ],
    [
      _KeySpec('4', 'four', CalculatorButtonStyle.number),
      _KeySpec('5', 'five', CalculatorButtonStyle.number),
      _KeySpec('6', 'six', CalculatorButtonStyle.number),
      _KeySpec('−', 'minus', CalculatorButtonStyle.operator),
    ],
    [
      _KeySpec('1', 'one', CalculatorButtonStyle.number),
      _KeySpec('2', 'two', CalculatorButtonStyle.number),
      _KeySpec('3', 'three', CalculatorButtonStyle.number),
      _KeySpec('+', 'plus', CalculatorButtonStyle.operator),
    ],
    [
      _KeySpec('0', 'zero', CalculatorButtonStyle.number),
      _KeySpec('.', 'decimal point', CalculatorButtonStyle.number),
      _KeySpec('⌫', 'backspace', CalculatorButtonStyle.destructive),
      _KeySpec('=', 'equals', CalculatorButtonStyle.equals),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: maxHeight),
        child: Column(
          children: [
            for (final row in _rows)
              Expanded(
                child: Row(
                  children: [
                    for (final key in row)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: CalculatorButton(
                            key: ValueKey('calculator-key-${key.label}'),
                            label: key.label,
                            semanticsLabel: key.semantics,
                            style: key.style,
                            onPressed: () => onKeyPressed(key.label),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KeySpec {
  const new(this.label, this.semantics, this.style);
  final String label;
  final String semantics;
  final CalculatorButtonStyle style;
}
