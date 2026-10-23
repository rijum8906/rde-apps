import 'package:app_routing/app_routing.dart';
import 'package:design_system/design_system.dart';

/// The calculator's typed route table.
///
/// Every page is declared once here so navigation can never drift from the
/// router registration in `app.dart`.
abstract final class CalculatorRoutes {
  /// The keypad page, and the first shell branch.
  static const AppRoute calculator = AppRoute(path: '/', name: 'calculator');

  /// The full history page.
  static const AppRoute history = AppRoute(path: '/history', name: 'history');

  /// The preferences page.
  static const AppRoute settings = AppRoute(
    path: '/settings',
    name: 'settings',
  );

  /// The about page, pushed above the shell so it covers the navigation.
  static const AppRoute about = AppRoute(
    path: '/about',
    name: 'about',
    transition: AppPageTransition.sharedAxisY,
  );
}
