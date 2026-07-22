import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static const TextTheme lightTextTheme = TextTheme(
    displayLarge: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.bold),
    headlineSmall: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.bold),
    titleMedium: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w700),
    titleSmall: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(color: AppColors.lightTextPrimary),
    bodyMedium: TextStyle(color: AppColors.lightTextSecondary),
    bodySmall: TextStyle(color: AppColors.lightTextSecondary),
    labelLarge: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(color: AppColors.lightTextSecondary),
    labelSmall: TextStyle(color: AppColors.lightTextSecondary),
  );

  static const TextTheme darkTextTheme = TextTheme(
    displayLarge: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold),
    headlineSmall: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold),
    titleMedium: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w700),
    titleSmall: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(color: AppColors.darkTextPrimary),
    bodyMedium: TextStyle(color: AppColors.darkTextSecondary),
    bodySmall: TextStyle(color: AppColors.darkTextSecondary),
    labelLarge: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(color: AppColors.darkTextSecondary),
    labelSmall: TextStyle(color: AppColors.darkTextSecondary),
  );
}
