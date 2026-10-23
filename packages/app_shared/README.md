# app_shared

Cross-app services that are independent of any single host: a dependency-free
`ServiceLocator` for composing interfaces at startup, `KeyValueStore` and
`SecureStore` abstractions over `shared_preferences` and
`flutter_secure_storage`, a `NotificationService` abstraction over
`flutter_local_notifications` with a no-op implementation, and platform/debug
helpers that work without `dart:io`.

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ServiceLocator.instance
    ..register<KeyValueStore>(PreferencesStore())
    ..register<SecureStore>(FlutterSecureStore())
    ..register<NotificationService>(NoopNotificationService())
    ..register<Logger>(createDebugLogger(name: 'desktop_app'));

  final store = ServiceLocator.instance.get<KeyValueStore>();
  unawaited(store.writeString('last_seen', DateTime.now().toIso8601String()));

  runApp(const DesktopApp());
}
```
