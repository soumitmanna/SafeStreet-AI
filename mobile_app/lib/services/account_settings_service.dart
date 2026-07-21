import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile_model.dart';
import '../services/profile_service.dart';

abstract class SettingsException implements Exception {
  final String message;
  const SettingsException(this.message);
}

class SettingsNotAuthenticatedException extends SettingsException {
  const SettingsNotAuthenticatedException() : super("Session expired. Please log in again.");
}

class SettingsOperationFailedException extends SettingsException {
  const SettingsOperationFailedException(String message) : super(message);
}

class AccountSettingsService {
  final FirebaseAuth _auth;
  final ProfileService _profileService;

  AccountSettingsService({FirebaseAuth? auth, ProfileService? profileService})
      : _auth = auth ?? FirebaseAuth.instance,
        _profileService = profileService ?? ProfileService();

  Future<UserProfileModel> loadAccountInfo() async {
    try {
      return await _profileService.loadProfile();
    } catch (e) {
      if (e is ProfileException) {
        throw SettingsOperationFailedException(e.message);
      }
      throw const SettingsOperationFailedException("Failed to load account information.");
    }
  }

  Future<void> signOut() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const SettingsNotAuthenticatedException();
    }
    
    try {
      await _auth.signOut();
    } catch (e) {
      throw const SettingsOperationFailedException("Failed to sign out. Please try again.");
    }
  }
}
