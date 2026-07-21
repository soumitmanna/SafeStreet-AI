// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';
import '../services/profile_service.dart';
import 'profile_controller.dart';

sealed class EditProfileState {}

class EditProfileIdle extends EditProfileState {}

class EditProfileEditing extends EditProfileState {
  final String displayName;
  final String? phoneNumber;
  EditProfileEditing(this.displayName, this.phoneNumber);
}

class EditProfileValidationError extends EditProfileState {
  final Map<String, String> fieldErrors;
  EditProfileValidationError(this.fieldErrors);
}

class EditProfileSaving extends EditProfileState {}

class EditProfileSaved extends EditProfileState {
  final UserProfileModel updatedProfile;
  EditProfileSaved(this.updatedProfile);
}

class EditProfileOffline extends EditProfileState {}

class EditProfileError extends EditProfileState {
  final ProfileException error;
  final String userMessage;
  EditProfileError(this.error, this.userMessage);
}

class EditProfileController extends ChangeNotifier {
  final UserProfileModel _initialProfile;
  final ProfileService _service;
  final ProfileController _profileController;

  EditProfileState _state = EditProfileIdle();
  EditProfileState get state => _state;

  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();

  String _lastAttemptedDisplayName = '';
  String? _lastAttemptedPhoneNumber;

  EditProfileController({
    required UserProfileModel initialProfile,
    required ProfileService service,
    required ProfileController profileController,
  })  : _initialProfile = initialProfile,
        _service = service,
        _profileController = profileController {
    displayNameController.text = _initialProfile.displayName;
    phoneNumberController.text = _initialProfile.phoneNumber ?? '';

    displayNameController.addListener(onFieldChanged);
    phoneNumberController.addListener(onFieldChanged);
  }

  void onFieldChanged() {
    if (_state is EditProfileSaving || _state is EditProfileSaved) return;

    final currentDisplayName = displayNameController.text.trim();
    final currentPhone = phoneNumberController.text.trim();
    final initialPhone = _initialProfile.phoneNumber ?? '';

    if (currentDisplayName != _initialProfile.displayName || currentPhone != initialPhone) {
      _state = EditProfileEditing(currentDisplayName, currentPhone.isEmpty ? null : currentPhone);
    } else {
      _state = EditProfileIdle();
    }
    notifyListeners();
  }

  Future<void> save() async {
    final displayName = displayNameController.text.trim();
    final phoneNumberStr = phoneNumberController.text.trim();
    final phoneNumber = phoneNumberStr.isEmpty ? null : phoneNumberStr;

    final errors = <String, String>{};

    // Validate Display Name
    if (displayName.isEmpty) {
      errors['displayName'] = 'Display name is required.';
    } else if (displayName.length < 2) {
      errors['displayName'] = 'Display name must be at least 2 characters.';
    } else if (displayName.length > 60) {
      errors['displayName'] = 'Display name must be 60 characters or less.';
    } else if (!RegExp(r"^[a-zA-Z\s'\-]+$").hasMatch(displayName)) {
      errors['displayName'] = 'Display name contains invalid characters.';
    }

    // Validate Phone Number
    if (phoneNumber != null) {
      final digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      if (!RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(phoneNumber)) {
        errors['phoneNumber'] = 'Phone number must contain only digits, spaces, +, -, and ().';
      } else if (digits.length < 7 || digits.length > 15) {
        errors['phoneNumber'] = 'Phone number must be between 7 and 15 digits.';
      }
    }

    if (errors.isNotEmpty) {
      _state = EditProfileValidationError(errors);
      notifyListeners();
      return;
    }

    final initialPhone = _initialProfile.phoneNumber ?? '';
    if (displayName == _initialProfile.displayName && (phoneNumber ?? '') == initialPhone) {
      // No changes to save
      _state = EditProfileIdle();
      notifyListeners();
      return;
    }

    _lastAttemptedDisplayName = displayName;
    _lastAttemptedPhoneNumber = phoneNumber;

    await _performSave(displayName, phoneNumber);
  }

  Future<void> retry() async {
    await _performSave(_lastAttemptedDisplayName, _lastAttemptedPhoneNumber);
  }

  Future<void> _performSave(String displayName, String? phoneNumber) async {
    _state = EditProfileSaving();
    notifyListeners();

    try {
      final updatedProfile = await _service.updateProfile(
        _initialProfile.uid,
        displayName: displayName,
        phoneNumber: phoneNumber,
      );
      
      if (!hasListeners) return;

      _profileController.invalidateCache();
      _state = EditProfileSaved(updatedProfile);
      notifyListeners();
    } on ProfileOfflineException {
      if (!hasListeners) return;
      _profileController.invalidateCache();
      _state = EditProfileOffline();
      notifyListeners();
    } on ProfileAuthExpiredException catch (e) {
      if (!hasListeners) return;
      _state = EditProfileError(e, e.message);
      notifyListeners();
    } on ProfileException catch (e) {
      if (!hasListeners) return;
      _state = EditProfileError(e, e.message);
      notifyListeners();
    } catch (e) {
      if (!hasListeners) return;
      const err = ProfileDataCorruptedException();
      _state = EditProfileError(err, err.message);
      notifyListeners();
    }
  }

  void cancel() {
    displayNameController.text = _initialProfile.displayName;
    phoneNumberController.text = _initialProfile.phoneNumber ?? '';
    _state = EditProfileIdle();
    notifyListeners();
  }

  @override
  void dispose() {
    displayNameController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }
}
