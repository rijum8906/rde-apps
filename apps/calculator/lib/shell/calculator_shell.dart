import 'package:app_routing/app_routing.dart';
import 'package:flutter/material.dart';

/// The responsive navigation chrome shared by the calculator pages.
///
/// Wide windows get a `NavigationRail` (extended on very wide windows); narrow
/// ones get a Material 3 `NavigationBar`. Both drive the router's indexed
/// shell, so the calculator keeps its state and each page keeps its scroll
/// position while switching tabs.
class CalculatorShell extends StatelessWidget {
  /// Creates the shell around [child].
  const new({required this.navigation, required this.child, super.key});

  /// The router's branch controller.
  final AppShellNavigation navigation;

  /// The page of the selected branch.
  final Widget child;

  /// Width at or above which the rail replaces the bottom bar.
  static const double railBreakpoint = 900;

  /// Width at or above which the rail also shows its labels inline.
  static const double extendedRailBreakpoint = 1180;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < railBreakpoint) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigation.currentIndex,
          onDestinationSelected: navigation.goToBranch,
          destinations: const [
            NavigationDestination(
              key: ValueKey('nav-calculator'),
              icon: Icon(Icons.calculate_outlined),
              selectedIcon: Icon(Icons.calculate),
              label: 'Calculator',
            ),
            NavigationDestination(
              key: ValueKey('nav-history'),
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'History',
            ),
            NavigationDestination(
              key: ValueKey('nav-settings'),
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune),
              label: 'Settings',
            ),
          ],
        ),
      );
    }

    final extended = width >= extendedRailBreakpoint;
    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              extended: extended,
              labelType: extended ? null : NavigationRailLabelType.all,
              selectedIndex: navigation.currentIndex,
              onDestinationSelected: navigation.goToBranch,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Icon(Icons.calculate_outlined, size: 28),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.calculate_outlined),
                  selectedIcon: Icon(Icons.calculate),
                  label: Text('Calculator'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: Text('History'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune),
                  label: Text('Settings'),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
