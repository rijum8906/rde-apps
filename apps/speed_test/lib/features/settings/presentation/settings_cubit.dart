import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speed_test/features/settings/data/settings_repository.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_profile.dart';

/// Owns the selected test profile and persists every change.
///
/// The theme is deliberately not part of this state: it is owned by the shared
/// `AppThemeController` from `app_theme`.
final class SettingsCubit extends Cubit<SpeedTestProfile> {
  /// Creates the cubit with the balanced profile until [load] finishes.
  new(this._repository) : super(SpeedTestProfile.balanced);

  final SettingsRepository _repository;

  /// Reads the persisted profile into the state.
  Future<void> load() async {
    final profile = await _repository.load();
    if (isClosed) {
      return;
    }
    emit(profile);
  }

  /// Selects [profile] for future runs.
  void setProfile(SpeedTestProfile profile) {
    if (profile == state) {
      return;
    }
    emit(profile);
    unawaited(_repository.save(profile));
  }

  /// Restores and forgets the profile.
  Future<void> restoreDefaults() async {
    if (state != SpeedTestProfile.balanced) {
      emit(SpeedTestProfile.balanced);
    }
    await _repository.reset();
  }
}
