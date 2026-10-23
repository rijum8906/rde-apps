import 'package:app_routing/app_routing.dart';
import 'package:calculator/features/calculator/presentation/bloc/calculator_bloc.dart';
import 'package:calculator/features/calculator/presentation/bloc/calculator_event.dart';
import 'package:calculator/features/calculator/presentation/bloc/calculator_state.dart';
import 'package:calculator/features/calculator/presentation/widgets/calculator_display.dart';
import 'package:calculator/features/calculator/presentation/widgets/calculator_keypad.dart';
import 'package:calculator/features/calculator/presentation/widgets/expand_toggle.dart';
import 'package:calculator/features/calculator/presentation/widgets/scientific_panel.dart';
import 'package:calculator/features/settings/presentation/settings_cubit.dart';
import 'package:calculator/routing/calculator_routes.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The keypad page: display, optional scientific panel, and the keypad.
///
/// The page is the only widget that touches [CalculatorBloc]; every child is a
/// dumb widget driven by callbacks.
class CalculatorPage extends StatefulWidget {
  /// Creates the page.
  const new({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  static final _numpadTokens = <LogicalKeyboardKey, String>{
    LogicalKeyboardKey.numpad0: '0',
    LogicalKeyboardKey.numpad1: '1',
    LogicalKeyboardKey.numpad2: '2',
    LogicalKeyboardKey.numpad3: '3',
    LogicalKeyboardKey.numpad4: '4',
    LogicalKeyboardKey.numpad5: '5',
    LogicalKeyboardKey.numpad6: '6',
    LogicalKeyboardKey.numpad7: '7',
    LogicalKeyboardKey.numpad8: '8',
    LogicalKeyboardKey.numpad9: '9',
    LogicalKeyboardKey.numpadAdd: '+',
    LogicalKeyboardKey.numpadSubtract: '-',
    LogicalKeyboardKey.numpadMultiply: '*',
    LogicalKeyboardKey.numpadDivide: '/',
    LogicalKeyboardKey.numpadDecimal: '.',
  };

  final FocusNode _focusNode = FocusNode(debugLabel: 'calculator');
  Listenable? _routeChanges;
  var _scientificExpanded = false;
  var _second = false;

  CalculatorBloc get _bloc => context.read<CalculatorBloc>();

  AngleMode get _angleMode => context.read<SettingsCubit>().state.angleMode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final changes = context.routeChanges;
    if (!identical(changes, _routeChanges)) {
      _routeChanges?.removeListener(_restoreFocus);
      _routeChanges = changes..addListener(_restoreFocus);
    }
  }

  /// Returns keyboard focus to the keypad after another tab was visited.
  void _restoreFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          context.isRouteActive(CalculatorRoutes.calculator) &&
          !_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _routeChanges?.removeListener(_restoreFocus);
    _focusNode.dispose();
    super.dispose();
  }

  void _add(String token) => _bloc.add(AppendToken(token));

  void _evaluate() => _bloc.add(EvaluateExpression(angleMode: _angleMode));

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        !context.isRouteActive(CalculatorRoutes.calculator)) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _evaluate();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _bloc.add(const ClearExpression());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace) {
      _bloc.add(const DeleteLastToken());
      return KeyEventResult.handled;
    }
    final numpadToken = _numpadTokens[key];
    if (numpadToken != null) {
      _add(numpadToken);
      return KeyEventResult.handled;
    }
    final character = event.character;
    if (character == '=') {
      _evaluate();
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
    'C' => _bloc.add(const ClearExpression()),
    '⌫' => _bloc.add(const DeleteLastToken()),
    '=' => _evaluate(),
    '÷' => _add('/'),
    '×' => _add('*'),
    '−' => _add('-'),
    _ => _add(label),
  };

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsCubit>();
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: BlocBuilder<CalculatorBloc, CalculatorState>(
        builder: (context, state) {
          final angleMode = context.select<SettingsCubit, AngleMode>(
            (cubit) => cubit.state.angleMode,
          );
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AppScaffold(
            title: 'Calculator',
            padding: EdgeInsets.zero,
            actions: [
              IconButton(
                key: const Key('theme-toggle'),
                tooltip: isDark ? 'Use light theme' : 'Use dark theme',
                onPressed: () => settings.setThemeMode(
                  isDark ? ThemeMode.light : ThemeMode.dark,
                ),
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                ),
              ),
            ],
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  children: [
                    CalculatorDisplay(
                      expression: state.expression.replaceAll('pi', 'π'),
                      result: state.resultText,
                      errorMessage: state.errorMessage,
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Give the keypad every pixel that is left, so keys
                          // stay visible without scrolling on normal windows.
                          final reserved = _scientificExpanded ? 360.0 : 0.0;
                          final keypadHeight =
                              (constraints.maxHeight - reserved - 73).clamp(
                                200.0,
                                CalculatorKeypad.maxHeight,
                              );
                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ExpandToggle(
                                    expanded: _scientificExpanded,
                                    onChanged: (value) => setState(
                                      () => _scientificExpanded = value,
                                    ),
                                  ),
                                ),
                                AnimatedSize(
                                  duration: context.motion.medium,
                                  curve: context.motion.emphasized,
                                  child: _scientificExpanded
                                      ? Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: ScientificPanel(
                                            second: _second,
                                            angleMode: angleMode,
                                            onSecondChanged: (value) =>
                                                setState(() => _second = value),
                                            onAngleModeChanged:
                                                settings.setAngleMode,
                                            onToken: _add,
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                const Divider(),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: keypadHeight,
                                  child: CalculatorKeypad(onKeyPressed: _key),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
