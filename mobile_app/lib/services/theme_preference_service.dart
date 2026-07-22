import 'package:flutter/material.dart';
import '../repositories/theme_preference_repository.dart';
import '../repositories/theme_preference_repository_impl.dart';

class ThemePreferenceService {
  final ThemePreferenceRepository _repository;

  ThemePreferenceService({ThemePreferenceRepository? repository})
      : _repository = repository ?? ThemePreferenceRepositoryImpl();

  Future<ThemeMode> getThemeMode() async {
    return await _repository.getThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _repository.setThemeMode(mode);
  }
}
