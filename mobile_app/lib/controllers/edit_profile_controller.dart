// ignore_for_file: prefer_initializing_formals

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
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

class EditProfileSelectingImage extends EditProfileState {}

class EditProfilePreviewing extends EditProfileState {
  final String localFilePath;
  EditProfilePreviewing(this.localFilePath);
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
  final TextEditingController medicalNotesController = TextEditingController();


  String? _previewFilePath;
  bool _removePhotoOnSave = false;

  String? _selectedGender;
  String? _selectedBloodGroup;

  String? get selectedGender => _selectedGender;
  String? get selectedBloodGroup => _selectedBloodGroup;
  String? get previewFilePath => _previewFilePath;
  bool get removePhotoOnSave => _removePhotoOnSave;

  EditProfileController({
    required UserProfileModel initialProfile,
    required ProfileService service,
    required ProfileController profileController,
  })  : _initialProfile = initialProfile,
        _service = service,
        _profileController = profileController {
    displayNameController.text = _initialProfile.displayName;
    phoneNumberController.text = _initialProfile.phoneNumber ?? '';
    
    _selectedGender = _initialProfile.gender?.toStorageString();
    _selectedBloodGroup = _initialProfile.bloodGroup?.toStorageString();
    medicalNotesController.text = _initialProfile.medicalNotes ?? '';

    displayNameController.addListener(onFieldChanged);
    phoneNumberController.addListener(onFieldChanged);
    medicalNotesController.addListener(onFieldChanged);
  }

  void onGenderChanged(String? val) {
    _selectedGender = val;
    onFieldChanged();
  }

  void onBloodGroupChanged(String? val) {
    _selectedBloodGroup = val;
    onFieldChanged();
  }

  bool _hasAnyChange() {
    final nameChanged = displayNameController.text.trim() != _initialProfile.displayName;
    final phoneChanged = phoneNumberController.text.trim() != (_initialProfile.phoneNumber ?? '');
    final genderChanged = _selectedGender != _initialProfile.gender?.toStorageString();
    final bloodChanged = _selectedBloodGroup != _initialProfile.bloodGroup?.toStorageString();
    final notesChanged = medicalNotesController.text.trim() != (_initialProfile.medicalNotes ?? '');
    final photoChanged = _previewFilePath != null || _removePhotoOnSave;
    
    return nameChanged || phoneChanged || genderChanged || bloodChanged || notesChanged || photoChanged;
  }

  void onFieldChanged() {
    if (_state is EditProfileSaving || _state is EditProfileSaved) return;
    if (_state is EditProfilePreviewing && _previewFilePath != null) return;

    if (_hasAnyChange()) {
      _state = EditProfileEditing(displayNameController.text.trim(), phoneNumberController.text.trim());
    } else {
      _state = EditProfileIdle();
    }
    notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    final sourceName = source == ImageSource.camera ? "Camera" : "Gallery";
    final previousState = _state;
    
    debugPrint('[EditProfile] Opening $sourceName...');
    _state = EditProfileSelectingImage();
    notifyListeners();

    XFile? pickedFile;
    try {
      final picker = ImagePicker();
      pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      debugPrint('[EditProfile] $sourceName opened.');
    } on PlatformException catch (e, stackTrace) {
      debugPrint('[EditProfile] PlatformException during $sourceName pick:\nCode: ${e.code}\nMessage: ${e.message}\nDetails: ${e.details}\nStackTrace: $stackTrace');
      
      final code = e.code.toLowerCase();
      if (code.contains('camera_access_denied') || (source == ImageSource.camera && code.contains('permission_denied'))) {
        _state = EditProfileError(const ProfileCameraPermissionDeniedException(), "Camera permission denied. Please enable camera access in app settings.");
      } else if (code.contains('photo_access_denied') || (source == ImageSource.gallery && code.contains('permission_denied'))) {
        _state = EditProfileError(const ProfileGalleryPermissionDeniedException(), "Gallery permission denied. Please enable photo access in app settings.");
      } else if (code.contains('no_available_camera') || code.contains('camera_unavailable')) {
        _state = EditProfileError(const ProfileCameraUnavailableException(), "Camera is unavailable on this device.");
      } else {
        _state = EditProfileError(const ProfileDataCorruptedException(), "Failed to access $sourceName: ${e.message ?? e.code}");
      }
      notifyListeners();
      return;
    } catch (e, stackTrace) {
      debugPrint('[EditProfile] Unexpected exception during $sourceName pick:\nException Type: ${e.runtimeType}\nException: $e\nStackTrace: $stackTrace');
      _state = EditProfileError(const ProfileDataCorruptedException(), "Unexpected error accessing $sourceName: $e");
      notifyListeners();
      return;
    }

    if (pickedFile == null) {
      debugPrint('[EditProfile] $sourceName closed without selecting an image (user cancelled).');
      _state = previousState;
      notifyListeners();
      return;
    }

    debugPrint('[EditProfile] Image selected.');

    final file = File(pickedFile.path);
    if (!file.existsSync()) {
      debugPrint('[EditProfile] Selected file does not exist on disk.');
      _state = EditProfileError(const ProfileInvalidImageFormatException(), "Selected file is unavailable on disk.");
      notifyListeners();
      return;
    }

    int originalSize = 0;
    try {
      originalSize = await file.length();
      debugPrint('[EditProfile] Original size: $originalSize bytes');
      if (originalSize > 5 * 1024 * 1024) {
        debugPrint('[EditProfile] Image exceeds 5MB limit.');
        _state = EditProfileError(const ProfileImageTooLargeException(), "Image is too large (max 5MB). Please select a smaller image.");
        notifyListeners();
        return;
      }
    } catch (e, stackTrace) {
      debugPrint('[EditProfile] Failed to read file length: $e\n$stackTrace');
    }

    final mimeType = pickedFile.mimeType ?? '';
    final ext = pickedFile.path.split('.').last.toLowerCase();
    debugPrint('[EditProfile] Image format check — mimeType: $mimeType, extension: $ext');
    if (!['jpeg', 'jpg', 'png', 'webp'].contains(ext) && !mimeType.startsWith('image/')) {
      debugPrint('[EditProfile] Unsupported format.');
      _state = EditProfileError(const ProfileInvalidImageFormatException(), "Unsupported image format. Please use JPEG, PNG, or WebP.");
      notifyListeners();
      return;
    }

    debugPrint('[EditProfile] Compression started.');
    XFile? compressedFile;
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/ss_avatar_${_initialProfile.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80,
        minWidth: 800,
        minHeight: 800,
        format: CompressFormat.jpeg,
      );

      if (compressedFile != null) {
        final compressedFileObj = File(compressedFile.path);
        final compressedSize = await compressedFileObj.length();
        debugPrint('[EditProfile] Compressed size: $compressedSize bytes');
        debugPrint('[EditProfile] Compression completed.');
        _previewFilePath = compressedFile.path;
      } else {
        debugPrint('[EditProfile] Compression returned null. Falling back to original image.');
        _previewFilePath = file.path;
      }
    } on UnimplementedError catch (e, stackTrace) {
      debugPrint('[EditProfile] Compression failed:');
      debugPrint('[EditProfile] Exception: $e');
      debugPrint('[EditProfile] StackTrace:\n$stackTrace');
      debugPrint('[EditProfile] UnimplementedError on platform. Falling back to original image.');
      _previewFilePath = file.path;
    } on MissingPluginException catch (e, stackTrace) {
      debugPrint('[EditProfile] Compression failed:');
      debugPrint('[EditProfile] Exception: $e');
      debugPrint('[EditProfile] StackTrace:\n$stackTrace');
      debugPrint('[EditProfile] MissingPluginException. Falling back to original image.');
      _previewFilePath = file.path;
    } catch (e, stackTrace) {
      debugPrint('[EditProfile] Compression failed:');
      debugPrint('[EditProfile] Exception: $e (${e.runtimeType})');
      debugPrint('[EditProfile] StackTrace:\n$stackTrace');
      if (file.existsSync()) {
        debugPrint('[EditProfile] Falling back to uncompressed original image.');
        _previewFilePath = file.path;
      } else {
        _state = EditProfileError(const ProfileImageCompressionException(), "Failed to compress selected image: $e");
        notifyListeners();
        return;
      }
    }

    _removePhotoOnSave = false;
    _state = EditProfilePreviewing(_previewFilePath!);
    debugPrint('[EditProfile] Preview updated.');
    notifyListeners();
  }

  void discardImagePreview() {
    debugPrint('[EditProfile] Discarding image preview...');
    _previewFilePath = null;
    onFieldChanged();
  }

  void markPhotoForRemoval() {
    debugPrint('[EditProfile] Marking photo for removal...');
    _removePhotoOnSave = true;
    _previewFilePath = null;
    onFieldChanged();
  }

  Future<void> save() async {
    final displayName = displayNameController.text.trim();
    final phoneNumberStr = phoneNumberController.text.trim();
    final phoneNumber = phoneNumberStr.isEmpty ? null : phoneNumberStr;
    final medicalNotesStr = medicalNotesController.text.trim();
    final medicalNotes = medicalNotesStr.isEmpty ? null : medicalNotesStr;

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

    if (medicalNotes != null && medicalNotes.length > 500) {
      errors['medicalNotes'] = 'Medical notes must be 500 characters or less.';
    }

    if (_previewFilePath != null) {
      if (!File(_previewFilePath!).existsSync()) {
        errors['photo'] = 'Selected image is no longer available. Please select again.';
        _previewFilePath = null;
      }
    }

    if (errors.isNotEmpty) {
      _state = EditProfileValidationError(errors);
      notifyListeners();
      return;
    }

    if (!_hasAnyChange()) {
      _state = EditProfileIdle();
      notifyListeners();
      return;
    }

    await _performSave(displayName, phoneNumber, medicalNotes);
  }

  Future<void> retry() async {
    await save();
  }

  Future<void> _performSave(String displayName, String? phoneNumber, String? medicalNotes) async {
    debugPrint('[EditProfile] Save started...');
    _state = EditProfileSaving();
    notifyListeners();

    try {
      final String? finalPhotoURL = _removePhotoOnSave ? null : _initialProfile.photoURL;

      final updatedProfile = await _service.updateFullProfile(
        _initialProfile.uid,
        displayName: displayName,
        phoneNumber: phoneNumber,
        photoURL: finalPhotoURL,
        newLocalImagePath: _removePhotoOnSave ? null : _previewFilePath,
        gender: _selectedGender,
        bloodGroup: _selectedBloodGroup,
        medicalNotes: medicalNotes,
        removePhoto: _removePhotoOnSave,
      );
      
      if (!hasListeners) return;

      _removePhotoOnSave = false;
      _previewFilePath = null;

      _profileController.invalidateCache();
      _state = EditProfileSaved(updatedProfile);
      debugPrint('[EditProfile] Firestore save finished. Profile updated successfully.');
      notifyListeners();
    } on ProfileOfflineException {
      debugPrint('[EditProfile] Save completed in offline mode.');
      if (!hasListeners) return;
      _profileController.invalidateCache();
      _state = EditProfileOffline();
      notifyListeners();
    } on ProfileAuthExpiredException catch (e) {
      debugPrint('[EditProfile] Save failed with AuthExpired: ${e.message}');
      if (!hasListeners) return;
      _state = EditProfileError(e, e.message);
      notifyListeners();
    } on ProfileException catch (e) {
      debugPrint('[EditProfile] Save failed with ProfileException: ${e.message}');
      if (!hasListeners) return;
      _state = EditProfileError(e, e.message);
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('[EditProfile] Save failed with unexpected exception:\n$e\n$stackTrace');
      if (!hasListeners) return;
      const err = ProfileDataCorruptedException();
      _state = EditProfileError(err, err.message);
      notifyListeners();
    }
  }

  void cancel() {
    displayNameController.text = _initialProfile.displayName;
    phoneNumberController.text = _initialProfile.phoneNumber ?? '';
    _selectedGender = _initialProfile.gender?.toStorageString();
    _selectedBloodGroup = _initialProfile.bloodGroup?.toStorageString();
    medicalNotesController.text = _initialProfile.medicalNotes ?? '';
    
    _previewFilePath = null;
    _removePhotoOnSave = false;
    
    _state = EditProfileIdle();
    notifyListeners();
  }

  @override
  void dispose() {
    displayNameController.dispose();
    phoneNumberController.dispose();
    medicalNotesController.dispose();
    super.dispose();
  }
}
