import 'dart:async';

import 'package:calculator/features/settings/data/settings_repository.dart';
import 'package:calculator/features/settings/domain/app_settings.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Owns the calculator preferences and persists every change.
///
/// The cubit is the single source of truth for the theme and the trigonometric
/// unit, so the settings page, the app shell, and the calculator always agree.
final class SettingsCubit extends Cubit<AppSettings> {
  /// Creates the cubit with the defaults until [load] finishes.
  new(this._repository) : super(AppSettings.defaults);

  final SettingsRepository _repository;

  /// Reads the persisted preferences into the state.
  Future<void> load() async {
    final settings = await _repository.load();
    if (isClosed) {
      return;
    }
    emit(settings);
  }

  /// Selects [mode] as the theme mode.
  void setThemeMode(ThemeMode mode) => _apply(state.copyWith(themeMode: mode));

  /// Selects [variant] as the Material 3 color variant.
  void setColorVariant(AppColorVariant variant) =>
      _apply(state.copyWith(colorVariant: variant));

  /// Selects [mode] as the trigonometric unit.
  void setAngleMode(AngleMode mode) => _apply(state.copyWith(angleMode: mode));

  /// Restores, and forgets, every preference.
  Future<void> restoreDefaults() async {
    if (state != AppSettings.defaults) {
      emit(AppSettings.defaults);
    }
    await _repository.reset();
  }

  void _apply(AppSettings settings) {
    if (settings == state) {
      return;
    }
    emit(settings);
    unawaited(_repository.save(settings));
  }
}
