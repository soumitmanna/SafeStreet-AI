import 'package:flutter/material.dart';
import 'light_theme.dart';
import 'dark_theme.dart';
export 'app_status_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => lightTheme;
  static ThemeData get dark => darkTheme;
}