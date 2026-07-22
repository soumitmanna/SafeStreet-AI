import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_preference_repository.dart';

class ThemePreferenceRepositoryImpl implements ThemePreferenceRepository {
  static const String _keyThemeMode = 'prefs_theme_mode';

  @override
  Future<ThemeMode> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex = prefs.getInt(_keyThemeMode);
      if (modeIndex == null || modeIndex < 0 || modeIndex >= ThemeMode.values.length) {
        return ThemeMode.system;
      }
      return ThemeMode.values[modeIndex];
    } catch (e, stackTrace) {
      debugPrint('Failed to load theme preference: $e\n$stackTrace');
      return ThemeMode.system;
    }
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyThemeMode, mode.index);
    } catch (e, stackTrace) {
      debugPrint('Failed to save theme preference: $e\n$stackTrace');
      throw Exception('Failed to save theme preference');
    }
  }
}
