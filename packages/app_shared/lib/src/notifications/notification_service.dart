import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// A thin abstraction over local notifications so apps never depend on a
/// concrete plugin at the call site.
abstract interface class NotificationService {
  /// Initializes the platform plugin and permission channels.
  ///
  /// Returns `true` when notifications can be shown.
  Future<bool> initialize();

  /// Shows a notification identified by [id].
  Future<void> show({
    required int id,
    required String title,
    String? body,
    String? payload,
  });

  /// Cancels every notification shown by the app.
  Future<void> cancelAll();
}

/// A [NotificationService] backed by `flutter_local_notifications`.
///
/// The workspace targets Linux desktops, where notifications are delivered
/// over the desktop notification daemon (D-Bus).
final class LocalNotificationService implements NotificationService {
  /// Creates the service, optionally wrapping an existing plugin instance.
  new({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<bool> initialize() async {
    final initialized = await _plugin.initialize(
      settings: const InitializationSettings(
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      ),
    );
    return initialized ?? false;
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    String? body,
    String? payload,
  }) {
    return _plugin.show(
      id: id,
      title: title,
      body: body,
      payload: payload,
      notificationDetails: const NotificationDetails(
        linux: LinuxNotificationDetails(),
      ),
    );
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}

/// A [NotificationService] that does nothing.
///
/// Useful in tests and behind a feature flag.
final class NoopNotificationService implements NotificationService {
  /// Creates the no-op service.
  const new();

  @override
  Future<bool> initialize() async => false;

  @override
  Future<void> show({
    required int id,
    required String title,
    String? body,
    String? payload,
  }) async {}

  @override
  Future<void> cancelAll() async {}
}
