import 'dart:async';

import 'package:app_routing/app_routing.dart';
import 'package:app_shared/app_shared.dart';
import 'package:app_theme/app_theme.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speed_test/features/about/presentation/pages/about_page.dart';
import 'package:speed_test/features/history/presentation/pages/history_page.dart';
import 'package:speed_test/features/settings/data/settings_repository.dart';
import 'package:speed_test/features/settings/presentation/settings_cubit.dart';
import 'package:speed_test/features/settings/presentation/settings_page.dart';
import 'package:speed_test/features/speed_test/domain/repositories/speed_test_repository.dart';
import 'package:speed_test/features/speed_test/domain/usecases/clear_speed_test_history.dart'
    as usecase;
import 'package:speed_test/features/speed_test/domain/usecases/load_speed_test_history.dart';
import 'package:speed_test/features/speed_test/domain/usecases/run_speed_test.dart';
import 'package:speed_test/features/speed_test/domain/usecases/save_speed_test_result.dart';
import 'package:speed_test/features/speed_test/presentation/bloc/speed_test_bloc.dart';
import 'package:speed_test/features/speed_test/presentation/bloc/speed_test_event.dart';
import 'package:speed_test/features/speed_test/presentation/pages/speed_test_page.dart';
import 'package:speed_test/routing/speed_test_routes.dart';
import 'package:speed_test/shell/speed_test_shell.dart';

/// The Linux speed test host.
///
/// Composition happens here: one bloc above the router so every page can read
/// the same state, one [AppThemeController] for the workspace theme, one cubit
/// for the test profile, and a typed router whose pages share the responsive
/// shell.
class SpeedTestApp extends StatefulWidget {
  /// Creates the app.
  const new({
    required this.store,
    required this.repository,
    this.themeSource,
    this.themeSink,
    super.key,
  });

  /// The key/value store used for preferences and the theme.
  final KeyValueStore store;

  /// The repository that measures and persists speed tests.
  final SpeedTestRepository repository;

  /// The desktop theme service to follow, when one is connected.
  final ThemeSource? themeSource;

  /// Where local theme changes are published so the desktop follows them.
  final ThemeSink? themeSink;

  @override
  State<SpeedTestApp> createState() => _SpeedTestAppState();
}

class _SpeedTestAppState extends State<SpeedTestApp> {
  late final SpeedTestBloc _bloc = SpeedTestBloc(
    runSpeedTest: RunSpeedTest(widget.repository),
    loadHistory: LoadSpeedTestHistory(widget.repository),
    saveResult: SaveSpeedTestResult(widget.repository),
    clearHistory: usecase.ClearSpeedTestHistory(widget.repository),
  )..add(const SpeedTestStarted());

  late final SettingsCubit _settings = SettingsCubit(
    SettingsRepository(widget.store),
  );

  late final AppThemeController _theme = AppThemeController(
    store: ThemeStore(widget.store),
    source: widget.themeSource,
    sink: widget.themeSink,
  );

  late final AppRouter _router = AppRouter(
    pages: [
      AppPage(
        route: SpeedTestRoutes.speedTest,
        builder: (_, _) => const SpeedTestPage(),
      ),
      AppPage(
        route: SpeedTestRoutes.history,
        builder: (_, _) => const HistoryPage(),
      ),
      AppPage(
        route: SpeedTestRoutes.settings,
        builder: (_, _) => const SettingsPage(),
      ),
    ],
    routes: [
      AppPage(
        route: SpeedTestRoutes.about,
        builder: (_, _) => const AboutPage(),
      ),
    ],
    shell: (context, navigation, child) =>
        SpeedTestShell(navigation: navigation, child: child),
  );

  @override
  void initState() {
    super.initState();
    unawaited(_settings.load());
    unawaited(_theme.start());
  }

  @override
  void dispose() {
    _router.dispose();
    unawaited(_bloc.close());
    unawaited(_settings.close());
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SpeedTestBloc>.value(value: _bloc),
        BlocProvider<SettingsCubit>.value(value: _settings),
      ],
      child: AppThemeScope(
        controller: _theme,
        // A media query above MaterialApp lets the theme honor the platform's
        // high-contrast request before ThemeData is built.
        child: MediaQuery.fromView(
          view: View.of(context),
          child: AppThemeBuilder(
            controller: _theme,
            builder: (context, light, dark, mode) {
              const motion = AppMotionTokens.standardTokens;
              return MaterialApp.router(
                title: 'Speed Test',
                debugShowCheckedModeBanner: false,
                theme: light,
                darkTheme: dark,
                themeMode: mode,
                themeAnimationDuration: motion.long,
                themeAnimationCurve: motion.emphasized,
                routerConfig: _router.router,
              );
            },
          ),
        ),
      ),
    );
  }
}
