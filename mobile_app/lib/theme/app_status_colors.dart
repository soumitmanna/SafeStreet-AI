import 'package:flutter/material.dart';

class AppStatusColors extends ThemeExtension<AppStatusColors> {
  final Color success;
  final Color warning;
  final Color info;
  final Color sos;
  final Color safeZone;
  final Color unsafeZone;

  const AppStatusColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.sos,
    required this.safeZone,
    required this.unsafeZone,
  });

  @override
  ThemeExtension<AppStatusColors> copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? sos,
    Color? safeZone,
    Color? unsafeZone,
  }) {
    return AppStatusColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      sos: sos ?? this.sos,
      safeZone: safeZone ?? this.safeZone,
      unsafeZone: unsafeZone ?? this.unsafeZone,
    );
  }

  @override
  ThemeExtension<AppStatusColors> lerp(
      covariant ThemeExtension<AppStatusColors>? other, double t) {
    if (other is! AppStatusColors) {
      return this;
    }
    return AppStatusColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      sos: Color.lerp(sos, other.sos, t)!,
      safeZone: Color.lerp(safeZone, other.safeZone, t)!,
      unsafeZone: Color.lerp(unsafeZone, other.unsafeZone, t)!,
    );
  }
}
