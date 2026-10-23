import 'package:app_shared/app_shared.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the service locator, platform helpers, and no-op services.
void main() {
  group('ServiceLocator', () {
    test('registers and resolves services by type', () {
      final locator = ServiceLocator();
      final store = _FakeStore();

      locator.register<KeyValueStore>(store);

      expect(locator.isRegistered<KeyValueStore>(), isTrue);
      expect(locator.get<KeyValueStore>(), same(store));
      expect(locator.maybeGet<KeyValueStore>(), same(store));
    });

    test('rejects duplicate registrations unless replaced', () {
      final locator = ServiceLocator()..register<KeyValueStore>(_FakeStore());

      expect(
        () => locator.register<KeyValueStore>(_FakeStore()),
        throwsStateError,
      );

      final replacement = _FakeStore();
      locator.register<KeyValueStore>(replacement, replace: true);
      expect(locator.get<KeyValueStore>(), same(replacement));
    });

    test('throws for missing services and supports cleanup', () {
      final locator = ServiceLocator();

      expect(() => locator.get<KeyValueStore>(), throwsStateError);
      expect(locator.maybeGet<KeyValueStore>(), isNull);

      locator
        ..register<KeyValueStore>(_FakeStore())
        ..unregister<KeyValueStore>();
      expect(locator.isRegistered<KeyValueStore>(), isFalse);

      locator
        ..register<KeyValueStore>(_FakeStore())
        ..reset();
      expect(locator.isRegistered<KeyValueStore>(), isFalse);
    });
  });

  group('PlatformInfo', () {
    test('describes the current platform consistently', () {
      expect(PlatformInfo.isWeb, isFalse);
      expect(PlatformInfo.label, isNotEmpty);
      expect(
        PlatformInfo.isDesktop || PlatformInfo.isMobile,
        isTrue,
        reason: 'Test hosts run on a supported platform.',
      );
      expect(PlatformInfo.isDesktop && PlatformInfo.isMobile, isFalse);
    });
  });

  group('Notifications', () {
    test('the noop service reports that it is unavailable', () async {
      const service = NoopNotificationService();

      expect(await service.initialize(), isFalse);
      await service.show(id: 1, title: 'Hello');
      await service.cancelAll();
    });
  });

  group('Debug helpers', () {
    test('logs through the core logger without throwing', () {
      final records = <LogRecord>[];
      final logger = CallbackLogger(records.add)..info('ready');

      debugLog('ready', name: 'test');

      expect(logger, isA<CallbackLogger>());
      expect(records.single.message, 'ready');
      expect(isDebugBuild, isTrue);
    });
  });
}

final class _FakeStore implements KeyValueStore {
  final Map<String, String> _values = {};

  @override
  Future<void> clear() async => _values.clear();

  @override
  Future<Set<String>> keys() async => _values.keys.toSet();

  @override
  Future<String?> readString(String key) async => _values[key];

  @override
  Future<void> remove(String key) async => _values.remove(key);

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }
}
