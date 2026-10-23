import 'package:app_shared/app_shared.dart';
import 'package:calculator/app.dart';
import 'package:calculator/features/calculator/data/datasources/calculator_local_data_source.dart';
import 'package:calculator/features/settings/data/settings_repository.dart';
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

/// Pumps the calculator and waits for history and settings to load.
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

/// Taps the keypad button with [label], scrolling it into view first.
Future<void> _tapKey(WidgetTester tester, String label) async {
  final key = find.byKey(ValueKey<String>('calculator-key-$label'));
  await tester.ensureVisible(key);
  await tester.pumpAndSettle();
  await tester.tap(key);
  await tester.pump();
}

/// Switches to the `calculator`, `history`, or `settings` tab.
Future<void> _openTab(WidgetTester tester, String tab) async {
  await tester.tap(find.byKey(ValueKey<String>('nav-$tab')));
  await tester.pumpAndSettle();
}

/// Opens the scientific panel and taps the function labelled [label].
Future<void> _tapScientific(WidgetTester tester, String label) async {
  final toggle = find.byKey(const Key('scientific-expand-toggle'));
  if (find.bySemanticsLabel(label).evaluate().isEmpty) {
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
  }
  final target = find.bySemanticsLabel(label);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pump();
}

/// Resizes the test surface and restores it afterwards.
void _setSize(WidgetTester tester, Size size) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
}

/// Covers input, history, appearance, and layout for the calculator app.
void main() {
  testWidgets('pressing 1 + 2 = shows 3 and saves history', (tester) async {
    final store = _FakeStore();
    await _pumpCalculator(tester, store);

    await _tapKey(tester, '1');
    await _tapKey(tester, '+');
    await _tapKey(tester, '2');
    await _tapKey(tester, '=');
    await tester.pumpAndSettle();

    expect(_expression(tester), '1+2');
    expect(_result(tester), '3');
    expect(store.values[CalculatorLocalDataSource.storageKey], contains('1+2'));
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

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(_expression(tester), '0');

    for (final label in ['1', '+', '2', '×', '3']) {
      await _tapKey(tester, label);
    }
    expect(_expression(tester), '1+2*3');
  });

  testWidgets('keyboard input still works after visiting another tab', (
    tester,
  ) async {
    await _pumpCalculator(tester, _FakeStore());

    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.pump();
    expect(_expression(tester), '1');

    await _openTab(tester, 'settings');
    await _openTab(tester, 'calculator');

    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.pump();
    expect(_expression(tester), '12');
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

  testWidgets('scientific panel inserts sine and pi evaluates', (tester) async {
    await _pumpCalculator(tester, _FakeStore());

    await _tapScientific(tester, 'sine');
    expect(_expression(tester), 'sin(');

    await _tapKey(tester, 'C');
    await _tapScientific(tester, 'pi');
    await _tapKey(tester, '=');
    await tester.pumpAndSettle();

    expect(_expression(tester), 'π');
    expect(double.parse(_result(tester)), closeTo(3.14159, .00001));
  });

  testWidgets('sin uses degrees by default', (tester) async {
    await _pumpCalculator(tester, _FakeStore());

    await _tapScientific(tester, 'sine');
    await _tapKey(tester, '3');
    await _tapKey(tester, '0');
    await _tapKey(tester, ')');
    await _tapKey(tester, '=');
    await tester.pumpAndSettle();

    expect(_result(tester), '0.5');
  });

  testWidgets('history page lists, restores, and clears calculations', (
    tester,
  ) async {
    final store = _FakeStore();
    await _pumpCalculator(tester, store);

    await _tapKey(tester, '1');
    await _tapKey(tester, '+');
    await _tapKey(tester, '2');
    await _tapKey(tester, '=');
    await tester.pumpAndSettle();
    await _tapKey(tester, 'C');

    await _openTab(tester, 'history');
    expect(find.text('1 of 20 saved'), findsOneWidget);

    await tester.tap(find.text('1+2'));
    await tester.pumpAndSettle();
    expect(_expression(tester), '1+2');
    expect(_result(tester), '3');

    await _openTab(tester, 'history');
    await tester.tap(find.byKey(const Key('history-clear')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('No calculations yet'), findsOneWidget);
    expect(store.values[CalculatorLocalDataSource.storageKey], isNull);
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

    final raw = store.values[CalculatorLocalDataSource.storageKey]!;
    expect(RegExp('"expression"').allMatches(raw).length, 20);
  });

  testWidgets('settings persist the theme and the app follows it', (
    tester,
  ) async {
    final store = _FakeStore();
    await _pumpCalculator(tester, store);
    await _openTab(tester, 'settings');

    expect(find.text('Appearance'), findsOneWidget);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    final appearance = find.text('Appearance');
    expect(Theme.of(tester.element(appearance)).brightness, Brightness.dark);
    expect(
      store.values[SettingsRepository.storageKey],
      contains('"themeMode":"dark"'),
    );

    await tester.tap(find.byKey(const ValueKey('color-vibrant')));
    await tester.pumpAndSettle();
    expect(
      store.values[SettingsRepository.storageKey],
      contains('"colorVariant":"vibrant"'),
    );
  });

  testWidgets('preferences survive a restart', (tester) async {
    final store = _FakeStore();
    await _pumpCalculator(tester, store);
    await _openTab(tester, 'settings');
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpCalculator(tester, store);

    final display = find.byKey(const Key('calculator-result'));
    expect(Theme.of(tester.element(display)).brightness, Brightness.dark);
    expect(
      Theme.of(tester.element(display)).colorScheme.primary,
      isNot(ThemeData.light().colorScheme.primary),
    );
  });

  testWidgets('the angle unit from settings is used when evaluating', (
    tester,
  ) async {
    final store = _FakeStore();
    await _pumpCalculator(tester, store);

    await _openTab(tester, 'settings');
    await tester.ensureVisible(find.text('RAD'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('RAD'));
    await tester.pumpAndSettle();
    expect(
      store.values[SettingsRepository.storageKey],
      contains('"angleMode":"radians"'),
    );

    await _openTab(tester, 'calculator');
    await _tapScientific(tester, 'sine');
    await tester.tap(find.bySemanticsLabel('pi'));
    await tester.pump();
    await _tapKey(tester, '÷');
    await _tapKey(tester, '2');
    await _tapKey(tester, ')');
    await _tapKey(tester, '=');
    await tester.pumpAndSettle();

    expect(_result(tester), '1');
  });

  testWidgets('about page opens from settings and lists shortcuts', (
    tester,
  ) async {
    await _pumpCalculator(tester, _FakeStore());
    await _openTab(tester, 'settings');

    await tester.scrollUntilVisible(
      find.text('About Calculator'),
      120,
      scrollable: find.descendant(
        of: find.byKey(const Key('settings-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.ensureVisible(find.text('About Calculator'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('About Calculator'));
    await tester.pumpAndSettle();

    expect(find.text('Version 1.0.0'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Enter ='),
      120,
      scrollable: find.descendant(
        of: find.byKey(const Key('about-list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Keyboard'), findsOneWidget);
    expect(find.text('Enter ='), findsOneWidget);
  });

  testWidgets('theme toggle switches brightness', (tester) async {
    await _pumpCalculator(tester, _FakeStore());

    final display = find.byKey(const Key('calculator-result'));
    expect(Theme.of(tester.element(display)).brightness, Brightness.light);

    await tester.tap(find.byKey(const Key('theme-toggle')));
    await tester.pumpAndSettle();

    expect(Theme.of(tester.element(display)).brightness, Brightness.dark);
  });

  testWidgets('narrow windows use the navigation bar and do not overflow', (
    tester,
  ) async {
    _setSize(tester, const Size(360, 600));
    await _pumpCalculator(tester, _FakeStore());

    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('='), findsOneWidget);

    await _openTab(tester, 'settings');
    expect(tester.takeException(), isNull);

    await _openTab(tester, 'history');
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide windows use the navigation rail and do not overflow', (
    tester,
  ) async {
    _setSize(tester, const Size(1200, 800));
    await _pumpCalculator(tester, _FakeStore());

    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('='), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
