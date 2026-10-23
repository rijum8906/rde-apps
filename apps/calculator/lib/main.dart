import 'package:app_shared/app_shared.dart';
import 'package:calculator/app.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Boots the calculator on Linux.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the window manager
  await windowManager.ensureInitialized();

  // Wide enough for the navigation rail; narrow windows still get the
  // bottom navigation bar down to the minimum size.
  const windowOptions = WindowOptions(
    size: Size(480, 750),
    minimumSize: Size(420, 650),
    center: true,
    title: 'Calculator',
  );

  // Wait until the window is ready before showing it to avoid visual flickers
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  ServiceLocator.instance.register<KeyValueStore>(PreferencesStore());

  runApp(CalculatorApp(store: ServiceLocator.instance.get<KeyValueStore>()));
}
