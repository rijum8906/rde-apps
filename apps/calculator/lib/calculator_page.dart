import 'package:calculator/features/calculator/presentation/bloc/calculator_bloc.dart';
import 'package:calculator/features/calculator/presentation/bloc/calculator_event.dart';
import 'package:calculator/features/calculator/presentation/bloc/calculator_state.dart';
import 'package:calculator/features/calculator/presentation/widgets/calculator_display.dart';
import 'package:calculator/features/calculator/presentation/widgets/calculator_keypad.dart';
import 'package:calculator/features/calculator/presentation/widgets/expand_toggle.dart';
import 'package:calculator/features/calculator/presentation/widgets/history_panel.dart';
import 'package:calculator/features/calculator/presentation/widgets/scientific_panel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Page boundary: the only calculator widget that accesses [CalculatorBloc].
class CalculatorPage extends StatefulWidget {
  const new({required this.onThemeModeChanged, super.key});
  final ValueChanged<ThemeMode> onThemeModeChanged;
  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final _focusNode = FocusNode(debugLabel: 'calculator');
  var _scientificExpanded = false;
  var _second = false;
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _add(String token) =>
      context.read<CalculatorBloc>().add(AppendToken(token));
  KeyEventResult _keys(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      context.read<CalculatorBloc>().add(const EvaluateExpression());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      context.read<CalculatorBloc>().add(const ClearExpression());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace) {
      context.read<CalculatorBloc>().add(const DeleteLastToken());
      return KeyEventResult.handled;
    }
    final character = event.character;
    if (character == '=') {
      context.read<CalculatorBloc>().add(const EvaluateExpression());
      return KeyEventResult.handled;
    }
    if (character != null &&
        RegExp(r'^[0-9.+*/%^()e-]$').hasMatch(character.toLowerCase())) {
      _add(character.toLowerCase());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _key(String label) => switch (label) {
    'C' => context.read<CalculatorBloc>().add(const ClearExpression()),
    '⌫' => context.read<CalculatorBloc>().add(const DeleteLastToken()),
    '=' => context.read<CalculatorBloc>().add(const EvaluateExpression()),
    '÷' => _add('/'),
    '×' => _add('*'),
    '−' => _add('-'),
    _ => _add(label),
  };
  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _focusNode,
    autofocus: true,
    onKeyEvent: _keys,
    child: BlocBuilder<CalculatorBloc, CalculatorState>(
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bloc = context.read<CalculatorBloc>();
        final science = ScientificPanel(
          second: _second,
          angleMode: state.angleMode,
          onSecondChanged: (value) => setState(() => _second = value),
          onAngleModeChanged: (value) => bloc.add(SetAngleMode(value)),
          onToken: _add,
        );
        return Scaffold(
          appBar: AppBar(
            title: const Text('Calculator'),
            actions: [
              Builder(
                builder: (scaffoldContext) => IconButton(
                  key: const Key('history-toggle'),
                  tooltip: 'History',
                  onPressed: () => Scaffold.of(scaffoldContext).openEndDrawer(),
                  icon: const Icon(Icons.history),
                ),
              ),
              IconButton(
                key: const Key('theme-toggle'),
                tooltip: isDark ? 'Use light theme' : 'Use dark theme',
                onPressed: () => widget.onThemeModeChanged(
                  isDark ? ThemeMode.light : ThemeMode.dark,
                ),
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                ),
              ),
            ],
          ),
          endDrawer: Drawer(
            child: SizedBox(
              width: 360,
              child: HistoryPanel(
                entries: state.history,
                onSelect: (item) {
                  bloc.add(LoadCalculation(item));
                  Navigator.of(context).pop();
                },
                onClear: () => bloc.add(const ClearHistory()),
                onClose: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                flex: 2,
                child: CalculatorDisplay(
                  expression: state.expression.replaceAll('pi', 'π'),
                  result: state.resultText,
                  errorMessage: state.errorMessage,
                ),
              ),
              Expanded(
                flex: 8,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: ExpandToggle(
                            expanded: _scientificExpanded,
                            onChanged: (value) =>
                                setState(() => _scientificExpanded = value),
                          ),
                        ),
                        AnimatedSize(
                          duration: AppMotionTokens.resolve(context).medium,
                          curve: AppMotionTokens.resolve(context).emphasized,
                          child: _scientificExpanded
                              ? Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: science,
                                )
                              : const SizedBox.shrink(),
                        ),
                        const Divider(),
                        CalculatorKeypad(onKeyPressed: _key),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
