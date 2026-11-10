import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_profile.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_progress.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_result.dart';
import 'package:speed_test/features/speed_test/domain/failures.dart';
import 'package:speed_test/features/speed_test/domain/usecases/clear_speed_test_history.dart'
    as usecase;
import 'package:speed_test/features/speed_test/domain/usecases/load_speed_test_history.dart';
import 'package:speed_test/features/speed_test/domain/usecases/run_speed_test.dart';
import 'package:speed_test/features/speed_test/domain/usecases/save_speed_test_result.dart';
import 'package:speed_test/features/speed_test/presentation/bloc/speed_test_event.dart';
import 'package:speed_test/features/speed_test/presentation/bloc/speed_test_state.dart';

/// Owns the measurement stream, the latest result, and the history list.
///
/// The bloc never talks to HttpClient or storage directly: it coordinates the
/// domain use cases and turns their updates into page state.
final class SpeedTestBloc extends Bloc<SpeedTestEvent, SpeedTestState> {
  /// Creates the bloc from its domain use cases.
  new({
    required this._runSpeedTest,
    required this._loadHistory,
    required this._saveResult,
    required this._clearHistory,
  }) : super(const SpeedTestState()) {
    on<SpeedTestStarted>(_onStarted);
    on<StartSpeedTest>(_onStart);
    on<CancelSpeedTest>(_onCancel);
    on<ClearSpeedTestHistory>(_onClearHistory);
    on<SpeedTestProgressReceived>(_onProgress);
    on<SpeedTestRunFailed>(_onFailed);
    on<SpeedTestRunClosed>(_onClosed);
  }

  final RunSpeedTest _runSpeedTest;
  final LoadSpeedTestHistory _loadHistory;
  final SaveSpeedTestResult _saveResult;
  final usecase.ClearSpeedTestHistory _clearHistory;

  StreamSubscription<SpeedTestProgress>? _subscription;
  SpeedTestProfile _activeProfile = SpeedTestProfile.balanced;

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await super.close();
  }

  Future<void> _onStarted(
    SpeedTestStarted event,
    Emitter<SpeedTestState> emit,
  ) async {
    switch (await _loadHistory()) {
      case Ok(:final value):
        final latest = value.isEmpty ? null : value.first;
        emit(
          SpeedTestState(
            history: value,
            result: latest,
            downloadBps: latest?.downloadBps,
            uploadBps: latest?.uploadBps,
            latencyMs: latest?.latencyMs,
            jitterMs: latest?.jitterMs,
            server: latest?.server,
          ),
        );
      case Err(:final error):
        emit(state.copyWith(errorMessage: error.message));
    }
  }

  Future<void> _onStart(
    StartSpeedTest event,
    Emitter<SpeedTestState> emit,
  ) async {
    if (state.isRunning) {
      return;
    }
    await _subscription?.cancel();
    _activeProfile = event.config.profile;
    emit(
      SpeedTestState(
        history: state.history,
        phase: SpeedTestPhase.connecting,
        isRunning: true,
      ),
    );
    _subscription = _runSpeedTest(event.config).listen(
      (progress) => add(SpeedTestProgressReceived(progress)),
      onError: (Object error, StackTrace stackTrace) =>
          add(SpeedTestRunFailed(error)),
      onDone: () => add(const SpeedTestRunClosed()),
      cancelOnError: true,
    );
  }

  void _onProgress(
    SpeedTestProgressReceived event,
    Emitter<SpeedTestState> emit,
  ) {
    if (isClosed || !state.isRunning) {
      return;
    }
    final progress = event.progress;
    if (!progress.isComplete) {
      emit(
        state.copyWith(
          phase: progress.phase,
          progress: progress.progress.clamp(0.0, 1.0),
          liveBps: progress.liveBps,
          downloadBps: progress.downloadBps,
          uploadBps: progress.uploadBps,
          latencyMs: progress.latencyMs,
          jitterMs: progress.jitterMs,
          server: progress.server,
          clearError: true,
        ),
      );
      return;
    }

    final result = SpeedTestResult.fromProgress(
      progress,
      profile: _activeProfile,
    );
    final history = [
      result,
      ...state.history,
    ].take(maxSpeedTestHistoryEntries).toList(growable: false);
    emit(
      SpeedTestState(
        phase: SpeedTestPhase.completed,
        progress: 1,
        liveBps: result.downloadBps,
        downloadBps: result.downloadBps,
        uploadBps: result.uploadBps,
        latencyMs: result.latencyMs,
        jitterMs: result.jitterMs,
        server: result.server,
        history: history,
        result: result,
      ),
    );
    unawaited(_saveResult(result));
  }

  Future<void> _onCancel(
    CancelSpeedTest event,
    Emitter<SpeedTestState> emit,
  ) async {
    // Return to the saved result immediately; tearing down the sockets can
    // take a moment and should not delay the Stop button.
    final subscription = _subscription;
    _subscription = null;
    final latest = state.history.isEmpty ? null : state.history.first;
    emit(
      SpeedTestState(
        history: state.history,
        result: latest,
        downloadBps: latest?.downloadBps,
        uploadBps: latest?.uploadBps,
        latencyMs: latest?.latencyMs,
        jitterMs: latest?.jitterMs,
        server: latest?.server,
      ),
    );
    await subscription?.cancel();
  }

  Future<void> _onClearHistory(
    ClearSpeedTestHistory event,
    Emitter<SpeedTestState> emit,
  ) async {
    await _clearHistory();
    emit(const SpeedTestState());
  }

  void _onFailed(SpeedTestRunFailed event, Emitter<SpeedTestState> emit) {
    if (isClosed) {
      return;
    }
    // The stream is cancelled by cancelOnError; drop the reference so a new
    // run can start without cancelling an already-finished subscription.
    _subscription = null;
    final error = event.error;
    emit(
      state.copyWith(
        phase: SpeedTestPhase.failed,
        isRunning: false,
        errorMessage: error is SpeedTestFailure
            ? error.message
            : 'The speed test could not finish. Please try again.',
      ),
    );
  }

  void _onClosed(SpeedTestRunClosed event, Emitter<SpeedTestState> emit) {
    if (isClosed || !state.isRunning) {
      return;
    }
    _subscription = null;
    emit(
      state.copyWith(
        phase: SpeedTestPhase.failed,
        isRunning: false,
        errorMessage: 'The speed test ended before it finished.',
      ),
    );
  }
}
