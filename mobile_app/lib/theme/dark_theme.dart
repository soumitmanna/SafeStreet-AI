import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_status_colors.dart';

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  primaryColor: AppColors.primaryBlue,
  scaffoldBackgroundColor: AppColors.darkBackground,
  textTheme: AppTypography.darkTextTheme,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.darkSurface,
    foregroundColor: AppColors.darkTextPrimary,
    elevation: 0,
    centerTitle: false,
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.darkBorder,
  ),
  cardTheme: CardThemeData(
    color: AppColors.darkSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: AppColors.darkBorder),
    ),
    elevation: 0,
  ),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF60A5FA), // lighter blue for dark mode contrast
    onPrimary: Color(0xFF0F172A),
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkTextPrimary,
    onSurfaceVariant: Color(0xFF94A3B8),
    surfaceContainer: Color(0xFF1E293B),
    surfaceContainerHighest: Color(0xFF334155),
    primaryContainer: Color(0xFF1E3A5F),
    onPrimaryContainer: Color(0xFF93C5FD),
    error: AppColors.emergencyRed,
    onError: Colors.white,
    inverseSurface: Color(0xFFE2E8F0),
    onInverseSurface: Color(0xFF1E293B),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.darkBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.darkBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 1.5),
    ),
    filled: false,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF60A5FA),
      foregroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF60A5FA),
      side: const BorderSide(color: AppColors.darkBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  ),
  dialogTheme: DialogThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    backgroundColor: AppColors.darkSurface,
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.darkSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    elevation: 0,
  ),
  switchTheme: SwitchThemeData(
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF60A5FA);
      }
      return null;
    }),
  ),
  extensions: const [
    AppStatusColors(
      success: AppColors.darkSuccess,
      warning: AppColors.darkWarning,
      info: AppColors.darkInfo,
      sos: AppColors.darkSos,
      safeZone: AppColors.darkSafeZone,
      unsafeZone: AppColors.darkUnsafeZone,
    ),
  ],
);
