import 'package:app_theme/src/app_theme_controller.dart';
import 'package:flutter/widgets.dart';

/// Exposes an [AppThemeController] to the widget tree.
///
/// Dependents rebuild when the selection changes, so any page can read the
/// theme without callbacks being threaded down:
///
/// ```dart
/// IconButton(
///   onPressed: () => AppThemeScope.of(context).setMode(ThemeMode.dark),
///   icon: const Icon(Icons.dark_mode_outlined),
/// );
/// ```
class AppThemeScope extends InheritedNotifier<AppThemeController> {
  /// Creates a scope for [controller].
  const new({
    required AppThemeController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  /// The nearest controller.
  ///
  /// Throws when no [AppThemeScope] is above [context]; use [maybeOf] when the
  /// scope is optional.
  static AppThemeController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'No AppThemeScope found above this context.');
    return controller!;
  }

  /// The nearest controller, or `null` when there is no scope.
  static AppThemeController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppThemeScope>()?.notifier;
}
