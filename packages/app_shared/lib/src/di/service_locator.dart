/// A minimal service locator used to compose app services at startup.
///
/// It is intentionally tiny: register concrete implementations in `main()` and
/// resolve interfaces (storage, notifications, logging) wherever they are
/// needed. Tests can create isolated instances instead of touching the global
/// one.
///
/// ```dart
/// ServiceLocator.instance.register<KeyValueStore>(PreferencesStore());
/// final store = ServiceLocator.instance.get<KeyValueStore>();
/// ```
final class ServiceLocator {
  /// Creates an isolated locator.
  new();

  /// The process-wide locator used by the host apps.
  static final ServiceLocator instance = ServiceLocator();

  final Map<Type, Object> _services = {};

  /// Registers [service] under its static type [T].
  ///
  /// Throws a [StateError] when [T] is already registered and [replace] is
  /// `false`, which catches accidental duplicate registrations at startup.
  void register<T extends Object>(T service, {bool replace = false}) {
    if (!replace && _services.containsKey(T)) {
      throw StateError('A service of type $T is already registered.');
    }
    _services[T] = service;
  }

  /// Returns the service registered for [T].
  ///
  /// Throws a [StateError] when nothing has been registered.
  T get<T extends Object>() {
    final service = _services[T];
    if (service == null) {
      throw StateError('No service registered for type $T.');
    }
    return service as T;
  }

  /// Returns the service registered for [T], or `null` when absent.
  T? maybeGet<T extends Object>() => _services[T] as T?;

  /// Whether a service is registered for [T].
  bool isRegistered<T extends Object>() => _services.containsKey(T);

  /// Removes the registration for [T], if any.
  void unregister<T extends Object>() => _services.remove(T);

  /// Removes every registration.
  void reset() => _services.clear();
}
