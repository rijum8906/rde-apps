import 'package:app_shared/app_shared.dart';
import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:speed_test/app.dart';
import 'package:speed_test/features/speed_test/data/datasources/cloudflare_speed_test_data_source.dart';
import 'package:speed_test/features/speed_test/data/datasources/fallback_speed_test_data_source.dart';
import 'package:speed_test/features/speed_test/data/datasources/fast_speed_test_data_source.dart';
import 'package:speed_test/features/speed_test/data/datasources/speed_test_local_data_source.dart';
import 'package:speed_test/features/speed_test/data/repositories/speed_test_repository_impl.dart';
import 'package:window_manager/window_manager.dart';

/// Boots the speed test on Linux.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(560, 880),
    minimumSize: Size(420, 680),
    center: true,
    title: 'Speed Test',
  );

  // Wait until the window is ready before showing it to avoid visual flickers.
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  ServiceLocator.instance.register<KeyValueStore>(PreferencesStore());
  final store = ServiceLocator.instance.get<KeyValueStore>();

  // Fast.com targets Netflix Open Connect appliances inside the user's ISP,
  // which is why its readings track fast.com. Cloudflare takes over if the
  // bootstrap call or server pick fails before any bytes are measured.
  final repository = SpeedTestRepositoryImpl(
    remote: FallbackSpeedTestDataSource(
      FastSpeedTestDataSource(),
      CloudflareSpeedTestDataSource(),
    ),
    local: SpeedTestLocalDataSource(store),
  );

  // The org.rde.Theme service is optional: when the desktop runs it, the
  // speed test adopts the desktop's Material palette and light/dark scheme,
  // and theme changes made here are published back to every app. The client
  // lives for the process.
  final theme = RdeThemeClient();

  runApp(
    SpeedTestApp(
      store: store,
      repository: repository,
      themeSource: theme,
      themeSink: theme,
    ),
  );
}
