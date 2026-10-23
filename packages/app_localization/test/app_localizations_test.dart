import 'package:app_localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps a widget that renders a value read from [AppLocalizations].
Widget _localizedApp({
  required String Function(AppLocalizations l10n) textOf,
  Locale? locale,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) {
        return Text(textOf(AppLocalizations.of(context)));
      },
    ),
  );
}

/// Verifies the generated delegates and both shipped locales.
void main() {
  test('English and German are supported', () {
    final codes = AppLocalizations.supportedLocales
        .map((locale) => locale.languageCode)
        .toSet();

    expect(codes, containsAll(<String>['en', 'de']));
  });

  testWidgets('English is the fallback locale', (tester) async {
    await tester.pumpWidget(_localizedApp(textOf: (l10n) => l10n.appTitle));
    await tester.pumpAndSettle();

    expect(find.text('Workspace'), findsOneWidget);
  });

  testWidgets('German strings load for the placeholder locale', (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        locale: const Locale('de'),
        textOf: (l10n) => l10n.welcomeBack('Ada'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Willkommen zurück, Ada'), findsOneWidget);
  });
}
