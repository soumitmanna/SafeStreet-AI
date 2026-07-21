import 'package:shared_preferences/shared_preferences.dart';
import 'notification_preference_repository.dart';

class SettingsPreferencesException implements Exception {
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;
  
  const SettingsPreferencesException(
    this.message, [
    this.originalError,
    this.stackTrace,
  ]);

  @override
  String toString() => 'SettingsPreferencesException: $message\nCaused by: $originalError';
}

class NotificationPreferenceRepositoryImpl implements NotificationPreferenceRepository {
  static const String _keyMaster = 'prefs_notifications_master_enabled';
  static const String _keyEmergencyAlert = 'prefs_notifications_emergency_alerts_enabled';
  static const String _keySosConfirmation = 'prefs_notifications_sos_confirmation_enabled';

  @override
  Future<bool> getMasterEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyMaster) ?? true;
    } catch (e, stackTrace) {
      throw SettingsPreferencesException("Failed to read master notification preference.", e, stackTrace);
    }
  }

  @override
  Future<bool> getEmergencyAlertEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyEmergencyAlert) ?? true;
    } catch (e, stackTrace) {
      throw SettingsPreferencesException("Failed to read emergency alert preference.", e, stackTrace);
    }
  }

  @override
  Future<bool> getSosConfirmationEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keySosConfirmation) ?? true;
    } catch (e, stackTrace) {
      throw SettingsPreferencesException("Failed to read SOS confirmation preference.", e, stackTrace);
    }
  }

  @override
  Future<void> setMasterEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyMaster, value);
    } catch (e, stackTrace) {
      throw SettingsPreferencesException("Failed to save master notification preference.", e, stackTrace);
    }
  }

  @override
  Future<void> setEmergencyAlertEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyEmergencyAlert, value);
    } catch (e, stackTrace) {
      throw SettingsPreferencesException("Failed to save emergency alert preference.", e, stackTrace);
    }
  }

  @override
  Future<void> setSosConfirmationEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySosConfirmation, value);
    } catch (e, stackTrace) {
      throw SettingsPreferencesException("Failed to save SOS confirmation preference.", e, stackTrace);
    }
  }
}
