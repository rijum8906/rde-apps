import 'dart:async';

import 'package:app_routing/app_routing.dart';
import 'package:app_shared/app_shared.dart';
import 'package:calculator/features/about/presentation/pages/about_page.dart';
import 'package:calculator/features/calculator/data/datasources/calculator_local_data_source.dart';
import 'package:calculator/features/calculator/data/repositories/calculator_repository_impl.dart';
import 'package:calculator/features/calculator/domain/usecases/add_to_history.dart'
    as usecase;
import 'package:calculator/features/calculator/domain/usecases/clear_history.dart'
    as usecase;
import 'package:calculator/features/calculator/domain/usecases/evaluate_expression.dart'
    as usecase;
import 'package:calculator/features/calculator/domain/usecases/load_history.dart'
    as usecase;
import 'package:calculator/features/calculator/presentation/bloc/calculator_bloc.dart';
import 'package:calculator/features/calculator/presentation/bloc/calculator_event.dart';
import 'package:calculator/features/calculator/presentation/pages/calculator_page.dart';
import 'package:calculator/features/history/presentation/pages/history_page.dart';
import 'package:calculator/features/settings/data/settings_repository.dart';
import 'package:calculator/features/settings/domain/app_settings.dart';
import 'package:calculator/features/settings/presentation/settings_cubit.dart';
import 'package:calculator/features/settings/presentation/settings_page.dart';
import 'package:calculator/routing/calculator_routes.dart';
import 'package:calculator/shell/calculator_shell.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The Linux calculator host.
///
/// Composition happens here: one calculator bloc above the router so every page
/// can read the same state, one settings cubit that owns the persisted theme
/// and angle unit, and a typed router whose pages share the responsive shell.
class CalculatorApp extends StatefulWidget {
  /// Creates the app.
  const new({required this.store, super.key});

  /// The key/value store used for history and preferences.
  final KeyValueStore store;

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  late final CalculatorRepositoryImpl _repository = CalculatorRepositoryImpl(
    CalculatorLocalDataSource(widget.store),
  );

  late final CalculatorBloc _calculatorBloc = CalculatorBloc(
    evaluateExpression: usecase.EvaluateExpression(_repository),
    loadHistory: usecase.LoadHistory(_repository),
    addToHistory: usecase.AddToHistory(_repository),
    clearHistory: usecase.ClearHistory(_repository),
  )..add(const CalculatorStarted());

  late final SettingsCubit _settingsCubit = SettingsCubit(
    SettingsRepository(widget.store),
  );

  late final AppRouter _router = AppRouter(
    pages: [
      AppPage(
        route: CalculatorRoutes.calculator,
        builder: (_, _) => const CalculatorPage(),
      ),
      AppPage(
        route: CalculatorRoutes.history,
        builder: (_, _) => const HistoryPage(),
      ),
      AppPage(
        route: CalculatorRoutes.settings,
        builder: (_, _) => const SettingsPage(),
      ),
    ],
    routes: [
      AppPage(
        route: CalculatorRoutes.about,
        builder: (_, _) => const AboutPage(),
      ),
    ],
    shell: (context, navigation, child) =>
        CalculatorShell(navigation: navigation, child: child),
  );

  @override
  void initState() {
    super.initState();
    unawaited(_settingsCubit.load());
  }

  @override
  void dispose() {
    _router.dispose();
    unawaited(_calculatorBloc.close());
    unawaited(_settingsCubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CalculatorBloc>.value(value: _calculatorBloc),
        BlocProvider<SettingsCubit>.value(value: _settingsCubit),
      ],
      child: BlocBuilder<SettingsCubit, AppSettings>(
        builder: (context, settings) {
          // A media query above MaterialApp lets the theme honor the
          // platform's high-contrast request before ThemeData is built.
          return MediaQuery.fromView(
            view: View.of(context),
            child: Builder(
              builder: (context) {
                final highContrast = MediaQuery.highContrastOf(context);
                const motion = AppMotionTokens.standardTokens;
                return MaterialApp.router(
                  title: 'Calculator',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.light(
                    variant: settings.colorVariant,
                    highContrast: highContrast,
                  ),
                  darkTheme: AppTheme.dark(
                    variant: settings.colorVariant,
                    highContrast: highContrast,
                  ),
                  themeMode: settings.themeMode,
                  themeAnimationDuration: motion.long,
                  themeAnimationCurve: motion.emphasized,
                  routerConfig: _router.router,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
