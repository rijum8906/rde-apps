# app_theme

One theme selection for every app in the workspace: `mode` (system, light,
dark) plus the Material 3 Expressive `AppColorVariant`.

The package provides the runtime layer only — the palette itself still comes
from `design_system`.

## Using it

```dart
final controller = AppThemeController(
  store: ThemeStore(ServiceLocator.instance.get<KeyValueStore>()),
);
await controller.start();

runApp(
  AppThemeScope(
    controller: controller,
    child: AppThemeBuilder(
      controller: controller,
      builder: (context, light, dark, mode) => MaterialApp(
        theme: light,
        darkTheme: dark,
        themeMode: mode,
        home: const HomePage(),
      ),
    ),
  ),
);
```

Any widget below the scope can change the theme and rebuild with it:

```dart
AppThemeScope.of(context).setMode(ThemeMode.dark);
```

## What it guarantees

- **Single source of truth.** `AppThemeController` owns the selection; the
  settings UI, the app bar toggle, and the `MaterialApp` all read it.
- **Persisted locally.** `ThemeStore` writes `{"mode": ..., "variant": ...}`
  under `app.theme` in the app's `KeyValueStore`. Corrupt or missing payloads
  fall back to `AppThemeSettings.defaults`; storage failures never block
  startup.
- **Ready for a shared service.** `ThemeSource` (read + stream) and
  `ThemeSink` (publish) are the only pieces a bus client needs to implement. A
  remote value wins over the local preference on startup, and remote changes
  are applied without being echoed back.

## Shared theme service — TODO

The `org.rde.Theme` session-bus service is **not implemented yet**. This is the
planned contract so the client can be dropped in without touching app code:

| Item | Value |
| --- | --- |
| Bus name | `org.rde.Theme` |
| Object path | `/org/rde/Theme` |
| Interface | `org.rde.Theme` |
| Methods | `GetTheme() → s`, `SetTheme(s)` |
| Signal | `ThemeChanged(s)` |

The string payload is exactly `AppThemeSettings.toJson()`, for example:

```json
{"mode": "dark", "variant": "expressive"}
```

`mode` is `system`, `light`, or `dark`; `variant` is one of
`expressive`, `vibrant`, `content`, `fidelity`, `monochrome`, `neutral`, or
`tonalSpot`. Unknown fields must be ignored so the service can grow.

When the service exists:

1. Add a `DbusThemeSource`/`DbusThemeSink` implementation of
   `ThemeSource`/`ThemeSink` in this package (or a sibling daemon package).
2. Pass them to `AppThemeController(source: ..., sink: ...)` in each app's
   composition root.
3. Nothing else changes: every app follows the bus and publishes its own
   changes.

Until then, apps pass no source or sink and simply persist locally.
