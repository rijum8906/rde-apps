import 'package:app_routing/app_routing.dart';
import 'package:app_shared/app_shared.dart';
import 'package:calculator/calculator_page.dart';
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
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The Linux calculator host.
///
/// The theme is resolved here and applied through [AnimatedThemeSwitcher] so
/// light/dark changes cross-fade with the shared motion tokens.
class CalculatorApp extends StatefulWidget {
  /// Creates the app.
  const new({required this.store, super.key});

  /// The key/value store used to persist the calculation history.
  final KeyValueStore store;

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  ThemeMode _themeMode = ThemeMode.system;

  late final AppRouter _router = AppRouter(
    homeBuilder: (context, state) => BlocProvider(
      create: (_) {
        final repository = CalculatorRepositoryImpl(
          CalculatorLocalDataSource(widget.store),
        );
        return CalculatorBloc(
          evaluateExpression: usecase.EvaluateExpression(repository),
          loadHistory: usecase.LoadHistory(repository),
          addToHistory: usecase.AddToHistory(repository),
          clearHistory: usecase.ClearHistory(repository),
        )..add(const CalculatorStarted());
      },
      child: CalculatorPage(
        onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
      ),
    ),
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: _router.router,
      builder: (context, child) {
        final highContrast = MediaQuery.highContrastOf(context);
        final platformIsDark =
            MediaQuery.platformBrightnessOf(context) == Brightness.dark;
        final theme = switch (_themeMode) {
          ThemeMode.light => AppTheme.light(highContrast: highContrast),
          ThemeMode.dark => AppTheme.dark(highContrast: highContrast),
          ThemeMode.system =>
            platformIsDark
                ? AppTheme.dark(highContrast: highContrast)
                : AppTheme.light(highContrast: highContrast),
        };

        return AnimatedThemeSwitcher(
          data: theme,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
