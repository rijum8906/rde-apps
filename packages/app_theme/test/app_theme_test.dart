import 'dart:async';

import 'package:app_shared/app_shared.dart';
import 'package:app_theme/app_theme.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
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

/// A controllable source, sink, and palette standing in for the theme service.
final class _FakeBus implements ThemeSource, ThemeSink, ThemePaletteSource {
  final StreamController<AppThemeSettings> _changes =
      StreamController<AppThemeSettings>.broadcast();
  final StreamController<AppDynamicColorSchemes?> _palettes =
      StreamController<AppDynamicColorSchemes?>.broadcast();
  final List<AppThemeSettings> published = <AppThemeSettings>[];
  AppThemeSettings? current;
  AppDynamicColorSchemes? palette;

  @override
  Future<AppThemeSettings?> read() async => current;

  @override
  Stream<AppThemeSettings> get changes => _changes.stream;

  @override
  Future<AppDynamicColorSchemes?> readPalette() async => palette;

  @override
  Stream<AppDynamicColorSchemes?> get paletteChanges => _palettes.stream;

  @override
  Future<void> publish(AppThemeSettings settings) async =>
      published.add(settings);

  void emit(AppThemeSettings settings) => _changes.add(settings);

  void emitPalette(AppDynamicColorSchemes? value) => _palettes.add(value);

  Future<void> close() async {
    await _changes.close();
    await _palettes.close();
  }
}

/// Covers the shared theme selection, persistence, and transport seam.
void main() {
  group('AppThemeSettings', () {
    test('round-trips through its stable JSON form', () {
      const settings = AppThemeSettings(
        mode: ThemeMode.dark,
        variant: AppColorVariant.vibrant,
      );

      expect(settings.toJson(), {'mode': 'dark', 'variant': 'vibrant'});
      expect(AppThemeSettings.fromJson(settings.toJson()), settings);
    });

    test('falls back per field for unknown values', () {
      final settings = AppThemeSettings.fromJson(const {
        'mode': 'sepia',
        'variant': 'vibrant',
      });

      expect(settings.mode, ThemeMode.system);
      expect(settings.variant, AppColorVariant.vibrant);
      expect(AppThemeSettings.fromJson('nonsense'), AppThemeSettings.defaults);
    });
  });

  group('ThemeStore', () {
    test('reads back what it writes and clears it', () async {
      final store = _FakeStore();
      final themeStore = ThemeStore(store);
      const settings = AppThemeSettings(mode: ThemeMode.light);

      await themeStore.write(settings);
      expect(await themeStore.read(), settings);
      expect(store.values, contains(ThemeStore.storageKey));

      await themeStore.clear();
      expect(await themeStore.read(), isNull);
    });
  });

  group('RdeThemePalette', () {
    const seed = Color(0xFF6DD6DA);

    test('maps the service role names onto both schemes', () {
      final palette = RdeThemePalette.fromRoles(
        light: const {
          'primary': '#00696C',
          'on_primary': '#FFFFFF',
          'surface': '#F4FBFA',
          'surface_container_highest': '#DDE4E3',
          'inverse_primary': '#80D4D7',
        },
        dark: const {'primary': '#80D4D7', 'surface': '#0E1415'},
        seedColor: seed,
      );

      expect(palette, isNotNull);
      expect(palette!.light.brightness, Brightness.light);
      expect(palette.light.primary, const Color(0xFF00696C));
      expect(palette.light.onPrimary, const Color(0xFFFFFFFF));
      expect(palette.light.surface, const Color(0xFFF4FBFA));
      expect(
        palette.light.surfaceContainerHighest,
        const Color(0xFFDDE4E3),
      );
      expect(palette.light.inversePrimary, const Color(0xFF80D4D7));
      expect(palette.dark.brightness, Brightness.dark);
      expect(palette.dark.primary, const Color(0xFF80D4D7));
      expect(palette.dark.surface, const Color(0xFF0E1415));
    });

    test('keeps the value generated from the seed for missing roles', () {
      final generated = AppColorSchemes.light(seedColor: seed);
      final palette = RdeThemePalette.fromRoles(
        light: const {'primary': '#000000'},
        dark: const {},
        seedColor: seed,
      );

      expect(palette!.light.primary, const Color(0xFF000000));
      expect(palette.light.secondary, generated.secondary);
      expect(palette.dark.brightness, Brightness.dark);
    });

    test('returns null when the service reports no roles', () {
      expect(
        RdeThemePalette.fromRoles(light: const {}, dark: const {}),
        isNull,
      );
    });
  });

  group('AppThemeController', () {
    test('restores the persisted selection on start', () async {
      final store = _FakeStore();
      await ThemeStore(store).write(
        const AppThemeSettings(
          mode: ThemeMode.dark,
          variant: AppColorVariant.content,
        ),
      );
      final controller = AppThemeController(store: ThemeStore(store));
      addTearDown(controller.dispose);

      await controller.start();

      expect(controller.mode, ThemeMode.dark);
      expect(controller.variant, AppColorVariant.content);
    });

    test('prefers the shared source over the local preference', () async {
      final store = _FakeStore();
      await ThemeStore(store)
          .write(const AppThemeSettings(mode: ThemeMode.light));
      final bus = _FakeBus()
        ..current = const AppThemeSettings(mode: ThemeMode.dark);
      addTearDown(bus.close);
      final controller = AppThemeController(
        store: ThemeStore(store),
        source: bus,
      );
      addTearDown(controller.dispose);

      await controller.start();

      expect(controller.mode, ThemeMode.dark);
    });

    test('persists and notifies when the selection changes', () async {
      final store = _FakeStore();
      final controller = AppThemeController(store: ThemeStore(store));
      addTearDown(controller.dispose);
      var notifications = 0;
      controller
        ..addListener(() => notifications++)
        ..setMode(ThemeMode.light)
        ..setVariant(AppColorVariant.fidelity);

      expect(notifications, 2);
      expect(store.values[ThemeStore.storageKey], contains('"mode":"light"'));
      expect(
        store.values[ThemeStore.storageKey],
        contains('"variant":"fidelity"'),
      );
    });

    test(
      'applies remote selections without persisting or echoing them',
      () async {
        final store = _FakeStore();
        final bus = _FakeBus();
        addTearDown(bus.close);
        final controller = AppThemeController(
          store: ThemeStore(store),
          source: bus,
          sink: bus,
        );
        addTearDown(controller.dispose);
        await controller.start();

        bus.emit(const AppThemeSettings(mode: ThemeMode.dark));
        await Future<void>.delayed(Duration.zero);

        expect(controller.mode, ThemeMode.dark);
        expect(store.values, isEmpty);
        expect(bus.published, isEmpty);
      },
    );

    test('publishes local selections to the sink', () async {
      final bus = _FakeBus();
      addTearDown(bus.close);
      final controller = AppThemeController(sink: bus);
      addTearDown(controller.dispose);

      controller.setMode(ThemeMode.dark);
      await Future<void>.delayed(Duration.zero);

      expect(bus.published, [const AppThemeSettings(mode: ThemeMode.dark)]);
    });

    test('follows a palette supplied by the source', () async {
      final bus = _FakeBus();
      addTearDown(bus.close);
      bus.palette = RdeThemePalette.fromRoles(
        light: const {'primary': '#00696C'},
        dark: const {'primary': '#80D4D7'},
      );
      final controller = AppThemeController(source: bus);
      addTearDown(controller.dispose);

      await controller.start();
      expect(controller.palette, bus.palette);

      final next = RdeThemePalette.fromRoles(
        light: const {'primary': '#FF6200'},
        dark: const {'primary': '#FFB59B'},
      );
      bus.emitPalette(next);
      await Future<void>.delayed(Duration.zero);

      expect(controller.palette, next);
    });

    test('reset clears the stored selection', () async {
      final store = _FakeStore();
      final controller = AppThemeController(store: ThemeStore(store));
      addTearDown(controller.dispose);
      controller.select(
        const AppThemeSettings(
          mode: ThemeMode.dark,
          variant: AppColorVariant.vibrant,
        ),
      );

      await controller.reset();

      expect(controller.settings, AppThemeSettings.defaults);
      expect(store.values, isEmpty);
    });
  });

  testWidgets('AppThemeBuilder renders the desktop palette', (tester) async {
    final bus = _FakeBus()
      ..palette = AppDynamicColorSchemes(
        light: AppColorSchemes.light(seedColor: const Color(0xFF00696C)),
        dark: AppColorSchemes.dark(seedColor: const Color(0xFF00696C)),
      );
    addTearDown(bus.close);
    final controller = AppThemeController(source: bus)
      ..setMode(ThemeMode.light);
    addTearDown(controller.dispose);
    await controller.start();

    await tester.pumpWidget(
      AppThemeBuilder(
        controller: controller,
        builder: (context, light, dark, mode) => MaterialApp(
          theme: light,
          darkTheme: dark,
          themeMode: mode,
          home: const SizedBox.shrink(),
        ),
      ),
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(
      app.theme?.colorScheme.primary,
      bus.palette!.light.primary,
    );
    expect(app.themeMode, ThemeMode.light);
  });

  testWidgets('AppThemeBuilder and AppThemeScope follow the controller', (
    tester,
  ) async {
    final controller = AppThemeController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      AppThemeScope(
        controller: controller,
        child: AppThemeBuilder(
          controller: controller,
          builder: (context, light, dark, mode) => MaterialApp(
            theme: light,
            darkTheme: dark,
            themeMode: mode,
            home: Builder(
              builder: (context) =>
                  Text('mode: ${AppThemeScope.of(context).mode.name}'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('mode: system'), findsOneWidget);

    controller.setMode(ThemeMode.dark);
    await tester.pumpAndSettle();

    expect(find.text('mode: dark'), findsOneWidget);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(app.theme?.colorScheme.brightness, Brightness.light);
    expect(app.darkTheme?.colorScheme.brightness, Brightness.dark);
  });
}
