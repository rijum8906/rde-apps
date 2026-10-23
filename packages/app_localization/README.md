# app_localization

ARB-based localization for the workspace apps. English is the template locale
and German is the placeholder second locale; `flutter gen-l10n` generates a
typed `AppLocalizations` class that bundles the Flutter and Material delegates.
Generated sources are committed so CI does not need a generation step, and
`flutter gen-l10n` regenerates them after ARB changes.

```dart
MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
  home: Builder(
    builder: (context) =>
        Text(AppLocalizations.of(context).welcomeBack('Ada')),
  ),
);
```
