import 'package:flutter/material.dart';
import '../services/theme_preference_service.dart';

class ThemeController extends ChangeNotifier {
  static final ThemeController _instance = ThemeController._internal();
  factory ThemeController() => _instance;
  ThemeController._internal() : _service = ThemePreferenceService();

  final ThemePreferenceService _service;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> loadTheme() async {
    _themeMode = await _service.getThemeMode();
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode newMode) async {
    if (_themeMode == newMode) return;
    
    _themeMode = newMode;
    notifyListeners();
    
    // Fire and forget persistence
    await _service.setThemeMode(newMode);
  }
}
