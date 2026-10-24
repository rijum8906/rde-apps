import 'dart:async';

import 'package:calculator/features/settings/data/settings_repository.dart';
import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Owns the calculator's trigonometric unit and persists every change.
///
/// The theme is deliberately not part of this state: it is owned by the
/// shared `AppThemeController` from `app_theme`, so every app can follow one
/// selection.
final class SettingsCubit extends Cubit<AngleMode> {
  /// Creates the cubit with degrees until [load] finishes.
  new(this._repository) : super(AngleMode.degrees);

  final SettingsRepository _repository;

  /// Reads the persisted unit into the state.
  Future<void> load() async {
    final mode = await _repository.load();
    if (isClosed) {
      return;
    }
    emit(mode);
  }

  /// Selects [mode] as the trigonometric unit.
  void setAngleMode(AngleMode mode) {
    if (mode == state) {
      return;
    }
    emit(mode);
    unawaited(_repository.save(mode));
  }

  /// Restores and forgets the unit.
  Future<void> restoreDefaults() async {
    if (state != AngleMode.degrees) {
      emit(AngleMode.degrees);
    }
    await _repository.reset();
  }
}
