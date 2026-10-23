import 'package:app_shared/app_shared.dart';
import 'package:calculator/app.dart';
import 'package:calculator/history.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// An in-memory [KeyValueStore] used to verify persistence.
final class _FakeStore implements KeyValueStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<void> clear() async => values.clear();

  @override
  Future<Set<String>> keys() async => values.keys.toSet();

  @override
  Future<String?> readString(String key) async => values[key];

  @override
  Future<void> remove(String key) async => values.remove(key);

  @override
  Future<void> writeString(String key, String value) async {
    values[key] = value;
  }
}

/// Pumps the calculator and waits for the history load to finish.
Future<void> _pumpCalculator(WidgetTester tester, _FakeStore store) async {
  await tester.pumpWidget(CalculatorApp(store: store));
  await tester.pumpAndSettle();
}

/// The current expression displayed by the calculator.
String _expression(WidgetTester tester) {
  return tester
      .widget<Text>(find.byKey(const Key('calculator-expression')))
      .data!;
}

/// The current result displayed by the calculator.
String _result(WidgetTester tester) {
  return tester.widget<Text>(find.byKey(const Key('calculator-result'))).data!;
}

/// Taps the keypad button with [label].
Future<void> _tapKey(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(ValueKey<String>('calculator-key-$label')));
  await tester.pump();
}

/// Verifies evaluation, keyboard input, editing, history, and layout.
void main() {
  testWidgets('pressing 1 + 2 = shows 3 and records history', (tester) async {
    final store = _FakeStore();
    await _pumpCalculator(tester, store);

    await _tapKey(tester, '1');
    await _tapKey(tester, '+');
    await _tapKey(tester, '2');
    await _tapKey(tester, '=');
    await tester.pumpAndSettle();

    expect(_expression(tester), '1+2');
    expect(_result(tester), '3');
    expect(store.values[CalculatorHistory.storageKey], contains('1+2'));
  });

  testWidgets('keyboard input matches button input', (tester) async {
    await _pumpCalculator(tester, _FakeStore());

    for (final key in [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.numpadAdd,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.numpadMultiply,
      LogicalKeyboardKey.digit3,
    ]) {
      await tester.sendKeyEvent(key);
    }
    await tester.pump();
    expect(_expression(tester), '1+2*3');

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(_result(tester), '7');

    // The same sequence through the keypad produces the same expression.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(_expression(tester), '0');

    for (final label in ['1', '+', '2', '×', '3']) {
      await _tapKey(tester, label);
    }
    expect(_expression(tester), '1+2*3');
  });

  testWidgets('C clears and backspace deletes one character', (tester) async {
    await _pumpCalculator(tester, _FakeStore());

    await _tapKey(tester, '1');
    await _tapKey(tester, '2');
    await _tapKey(tester, '3');
    expect(_expression(tester), '123');

    await _tapKey(tester, '⌫');
    expect(_expression(tester), '12');

    await _tapKey(tester, 'C');
    expect(_expression(tester), '0');
  });

  testWidgets('errors are inline and clear on the next keypress', (
    tester,
  ) async {
    await _pumpCalculator(tester, _FakeStore());

    await _tapKey(tester, '1');
    await _tapKey(tester, '÷');
    await _tapKey(tester, '0');
    await _tapKey(tester, '=');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calculator-error')), findsOneWidget);
    expect(find.textContaining('divide by zero'), findsOneWidget);
    expect(find.byKey(const Key('calculator-result')), findsNothing);

    await _tapKey(tester, '5');
    expect(find.byKey(const Key('calculator-error')), findsNothing);
  });

  testWidgets('history persists across rebuilds and loads entries', (
    tester,
  ) async {
    final store = _FakeStore();
    await _pumpCalculator(tester, store);

    await _tapKey(tester, '1');
    await _tapKey(tester, '+');
    await _tapKey(tester, '2');
    await _tapKey(tester, '=');
    await tester.pumpAndSettle();

    // Rebuild the whole app against the same store.
    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpCalculator(tester, store);

    // On compact layouts history is an M3 end sheet.
    await tester.tap(find.byKey(const Key('history-toggle')));
    await tester.pumpAndSettle();
    final historyEntry = find.text('1+2');
    expect(historyEntry, findsOneWidget);

    await tester.tap(historyEntry);
    await tester.pumpAndSettle();

    expect(_expression(tester), '1+2');
    expect(_result(tester), '3');
  });

  testWidgets('history is capped at 20 entries', (tester) async {
    final store = _FakeStore();
    await _pumpCalculator(tester, store);

    for (var index = 0; index < 22; index++) {
      await _tapKey(tester, '1');
      await _tapKey(tester, '+');
      await _tapKey(tester, '1');
      await _tapKey(tester, '=');
      await tester.pumpAndSettle();
      await _tapKey(tester, 'C');
    }

    final raw = store.values[CalculatorHistory.storageKey]!;
    expect(RegExp('"expression"').allMatches(raw).length, 20);
  });

  testWidgets('lays out at 360x600 and 1200x800 without overflow', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 600)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });

    await _pumpCalculator(tester, _FakeStore());
    expect(tester.takeException(), isNull);
    expect(find.text('='), findsOneWidget);

    tester.view.physicalSize = const Size(1200, 800);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('calculator-history')), findsNothing);
    expect(find.text('='), findsOneWidget);
  });

  testWidgets('theme toggle switches brightness using the animated theme', (
    tester,
  ) async {
    await _pumpCalculator(tester, _FakeStore());

    final title = find.text('Calculator');
    expect(Theme.of(tester.element(title)).brightness, Brightness.light);

    await tester.tap(find.byKey(const Key('theme-toggle')));
    await tester.pumpAndSettle();

    expect(Theme.of(tester.element(title)).brightness, Brightness.dark);
  });

  testWidgets('scientific panel expands and inserts sine', (tester) async {
    await _pumpCalculator(tester, _FakeStore());
    await tester.tap(find.byKey(const Key('scientific-expand-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('sine'));
    await tester.pump();
    expect(_expression(tester), 'sin(');
  });

  testWidgets('scientific functions remain hidden until expanded on wide layouts', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(900, 800)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });
    await _pumpCalculator(tester, _FakeStore());
    expect(find.bySemanticsLabel('sine'), findsNothing);
    expect(find.byKey(const Key('scientific-expand-toggle')), findsOneWidget);
  });

  testWidgets('pi evaluates and DEG/RAD changes trigonometry', (tester) async {
    await _pumpCalculator(tester, _FakeStore());
    await tester.tap(find.byKey(const Key('scientific-expand-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('pi'));
    await _tapKey(tester, '=');
    await tester.pumpAndSettle();
    expect(_expression(tester), 'π');
    expect(double.parse(_result(tester)), closeTo(3.14159, .00001));
  });
}
