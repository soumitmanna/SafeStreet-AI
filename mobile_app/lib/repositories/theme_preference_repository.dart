import 'package:flutter/material.dart';

abstract class ThemePreferenceRepository {
  Future<ThemeMode> getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);
}
