import 'package:flutter/foundation.dart';
import '../models/user_profile_model.dart';
import '../services/account_settings_service.dart';

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

class AccountSettingsController extends ChangeNotifier {
  final AccountSettingsService _service;
  
  AccountSettingsState _state = AccountSettingsIdle();
  AccountSettingsState get state => _state;

  AccountSettingsController({AccountSettingsService? service}) 
      : _service = service ?? AccountSettingsService();

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
}
