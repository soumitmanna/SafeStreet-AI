import 'package:flutter/foundation.dart';
import '../models/user_profile_model.dart';
import '../models/notification_preferences_model.dart';
import '../services/account_settings_service.dart';
import '../services/notification_preference_service.dart';

sealed class AccountSettingsState {}

class AccountSettingsIdle extends AccountSettingsState {}

class AccountSettingsLoading extends AccountSettingsState {}

class AccountSettingsLoaded extends AccountSettingsState {
  final UserProfileModel profile;
  AccountSettingsLoaded(this.profile);
}

class AccountSettingsError extends AccountSettingsState {
  final SettingsException error;
  AccountSettingsError(this.error);
}

sealed class AccountSettingsNotificationState {}

class AccountSettingsNotificationLoading extends AccountSettingsNotificationState {}

class AccountSettingsNotificationLoaded extends AccountSettingsNotificationState {
  final NotificationPreferencesModel prefs;
  AccountSettingsNotificationLoaded(this.prefs);
}

class AccountSettingsNotificationError extends AccountSettingsNotificationState {
  final String error;
  AccountSettingsNotificationError(this.error);
}

class AccountSettingsController extends ChangeNotifier {
  final AccountSettingsService _service;
  final NotificationPreferenceService _notificationService;
  
  AccountSettingsState _state = AccountSettingsIdle();
  AccountSettingsState get state => _state;

  AccountSettingsNotificationState _notificationState = AccountSettingsNotificationLoading();
  AccountSettingsNotificationState get notificationState => _notificationState;

  AccountSettingsController({
    AccountSettingsService? service,
    NotificationPreferenceService? notificationService,
  })  : _service = service ?? AccountSettingsService(),
        _notificationService = notificationService ?? NotificationPreferenceService();

  Future<void> initialize() async {
    _state = AccountSettingsLoading();
    notifyListeners();

    try {
      final profile = await _service.loadAccountInfo();
      _state = AccountSettingsLoaded(profile);
    } on SettingsException catch (e) {
      _state = AccountSettingsError(e);
    } catch (e) {
      _state = AccountSettingsError(const SettingsOperationFailedException("An unexpected error occurred."));
    }

    try {
      final prefs = await _notificationService.loadPreferences();
      _notificationState = AccountSettingsNotificationLoaded(prefs);
    } catch (e, stackTrace) {
      debugPrint('Failed to load notification settings: $e\n$stackTrace');
      _notificationState = AccountSettingsNotificationError("Failed to load notification settings.");
    }

    notifyListeners();
  }

  Future<void> logout() async {
    // We do not change state to loading here as we expect the UI to handle
    // the progress and navigation based on the Future returned.
    try {
      await _service.signOut();
    } on SettingsException {
      rethrow;
    } catch (e) {
      throw const SettingsOperationFailedException("Failed to log out.");
    }
  }

  Future<void> setMasterNotificationEnabled(bool value) async {
    try {
      await _notificationService.setMasterEnabled(value);
      await _reloadNotifications();
    } catch (e, stackTrace) {
      debugPrint('Failed to set master notification: $e\n$stackTrace');
    }
  }

  Future<void> setEmergencyAlertNotifications(bool value) async {
    try {
      await _notificationService.setEmergencyAlertEnabled(value);
      await _reloadNotifications();
    } catch (e, stackTrace) {
      debugPrint('Failed to set emergency alert notifications: $e\n$stackTrace');
    }
  }

  Future<void> setSosConfirmationNotifications(bool value) async {
    try {
      await _notificationService.setSosConfirmationEnabled(value);
      await _reloadNotifications();
    } catch (e, stackTrace) {
      debugPrint('Failed to set SOS confirmation notifications: $e\n$stackTrace');
    }
  }

  Future<void> _reloadNotifications() async {
    try {
      final prefs = await _notificationService.loadPreferences();
      _notificationState = AccountSettingsNotificationLoaded(prefs);
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Failed to reload notifications: $e\n$stackTrace');
      // Keep existing state on error
    }
  }
}
