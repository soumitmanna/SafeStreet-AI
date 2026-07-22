import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Shared Colors
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color emergencyRed = Color(0xFFEF4444);
  static const Color warningOrange = Colors.orange;
  // Status Colors - Light
  static const Color lightSuccess = Color(0xFF16A34A);
  static const Color lightWarning = Colors.orange;
  static const Color lightInfo = Color(0xFF2563EB); // primaryBlue
  static const Color lightSos = Color(0xFFDC2626);
  static const Color lightSafeZone = Color(0xFF16A34A);
  static const Color lightUnsafeZone = Color(0xFFDC2626);

  // Status Colors - Dark
  static const Color darkSuccess = Color(0xFF22C55E); // lighter green for dark mode
  static const Color darkWarning = Color(0xFFFBBF24); // lighter orange
  static const Color darkInfo = Color(0xFF60A5FA); // lighter blue
  static const Color darkSos = Color(0xFFEF4444); // lighter red
  static const Color darkSafeZone = Color(0xFF22C55E);
  static const Color darkUnsafeZone = Color(0xFFEF4444);
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Colors.black54;
  static const Color lightBorder = Colors.black12;

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Colors.white70;
  static const Color darkBorder = Colors.white12;
}
