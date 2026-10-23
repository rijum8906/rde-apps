import 'package:bloc/bloc.dart';
import 'package:calculator/features/calculator/domain/failures.dart';
import 'package:calculator/features/calculator/domain/usecases/add_to_history.dart'
    as usecase;
import 'package:calculator/features/calculator/domain/usecases/clear_history.dart'
    as usecase;
import 'package:calculator/features/calculator/domain/usecases/evaluate_expression.dart'
    as usecase;
import 'package:calculator/features/calculator/domain/usecases/load_history.dart'
    as usecase;
import 'package:calculator/features/calculator/domain/usecases/no_params.dart';
import 'package:calculator/features/calculator/presentation/bloc/calculator_event.dart';
import 'package:calculator/features/calculator/presentation/bloc/calculator_state.dart';
import 'package:calculator/result_format.dart';
import 'package:core/core.dart';

/// Owns calculator interaction state and coordinates domain use cases.
class CalculatorBloc extends Bloc<CalculatorEvent, CalculatorState> {
  /// Creates the bloc from its domain use cases.
  new({
    required this._evaluateExpression,
    required this._loadHistory,
    required this._addToHistory,
    required this._clearHistory,
  }) : super(const CalculatorState()) {
    on<CalculatorStarted>(_onStarted);
    on<AppendToken>(_onAppend);
    on<ClearExpression>(
      (event, emit) => emit(
        state.copyWith(
          expression: '',
          clearResult: true,
          clearError: true,
          justEvaluated: false,
        ),
      ),
    );
    on<DeleteLastToken>(_onBackspace);
    on<EvaluateExpression>(_onEvaluate);
    on<LoadCalculation>(_onLoad);
    on<ClearHistory>(_onClearHistory);
  }
  final usecase.EvaluateExpression _evaluateExpression;
  final usecase.LoadHistory _loadHistory;
  final usecase.AddToHistory _addToHistory;
  final usecase.ClearHistory _clearHistory;
  static const _operators = {'+', '-', '*', '/', '^'};

  Future<void> _onStarted(
    CalculatorStarted event,
    Emitter<CalculatorState> emit,
  ) async {
    switch (await _loadHistory(const NoParams())) {
      case Ok(:final value):
        emit(state.copyWith(history: value));
      case Err():
        break;
    }
  }

  void _onAppend(AppendToken event, Emitter<CalculatorState> emit) {
    final continues = _operators.contains(event.token);
    final expression = state.justEvaluated
        ? (continues ? '${state.resultText ?? ''}${event.token}' : event.token)
        : '${state.expression}${event.token}';
    emit(
      state.copyWith(
        expression: expression,
        clearResult: !continues,
        clearError: true,
        justEvaluated: false,
      ),
    );
  }

  void _onBackspace(DeleteLastToken event, Emitter<CalculatorState> emit) {
    if (state.expression.isEmpty) return;
    emit(
      state.copyWith(
        expression: state.expression.substring(0, state.expression.length - 1),
        clearResult: true,
        clearError: true,
        justEvaluated: false,
      ),
    );
  }

  Future<void> _onEvaluate(
    EvaluateExpression event,
    Emitter<CalculatorState> emit,
  ) async {
    if (state.expression.trim().isEmpty) {
      emit(
        state.copyWith(
          errorMessage: const EmptyExpressionFailure().message,
          clearResult: true,
        ),
      );
      return;
    }
    switch (await _evaluateExpression(
      usecase.EvaluationParams(
        expression: state.expression,
        angleMode: event.angleMode,
      ),
    )) {
      case Ok(:final value):
        final history = [value, ...state.history];
        emit(
          state.copyWith(
            resultText: formatResult(value.result),
            clearError: true,
            history: history,
            justEvaluated: true,
          ),
        );
        await _addToHistory(value);
      case Err(:final error):
        emit(
          state.copyWith(
            errorMessage: error.message,
            clearResult: true,
            justEvaluated: false,
          ),
        );
    }
  }

  void _onLoad(LoadCalculation event, Emitter<CalculatorState> emit) => emit(
    state.copyWith(
      expression: event.calculation.expression,
      resultText: formatResult(event.calculation.result),
      clearError: true,
      justEvaluated: false,
    ),
  );
  Future<void> _onClearHistory(
    ClearHistory event,
    Emitter<CalculatorState> emit,
  ) async {
    await _clearHistory(const NoParams());
    emit(state.copyWith(history: const []));
  }
}
