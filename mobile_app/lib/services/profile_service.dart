
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile_model.dart';
import '../repositories/profile_repository.dart';
import '../repositories/profile_repository_impl.dart';
import 'local_profile_image_service.dart';

abstract class ProfileException implements Exception {
  final String message;
  const ProfileException(this.message);
}

class ProfileNotAuthenticatedException extends ProfileException {
  const ProfileNotAuthenticatedException() : super("Session expired. Please log in again.");
}
class ProfileDocumentMissingException extends ProfileException {
  const ProfileDocumentMissingException() : super("Profile not found. Setting up your account…");
}
class ProfileNetworkException extends ProfileException {
  const ProfileNetworkException() : super("No internet connection. Showing cached data.");
}
class ProfileFirestoreUnavailableException extends ProfileException {
  const ProfileFirestoreUnavailableException() : super("Service temporarily unavailable. Please try again.");
}
class ProfileAuthExpiredException extends ProfileException {
  const ProfileAuthExpiredException() : super("Your session has expired. Please log in again.");
}
class ProfileDataCorruptedException extends ProfileException {
  const ProfileDataCorruptedException() : super("Profile data is corrupted. Please contact support.");
}

class ProfileOfflineException extends ProfileException {
  const ProfileOfflineException() : super("No internet connection. Your changes will sync when you reconnect.");
}

class ProfileValidationException extends ProfileException {
  final String field;
  final String reason;
  ProfileValidationException(this.field, this.reason) : super(reason);
}



class ProfileImageTooLargeException extends ProfileException {
  const ProfileImageTooLargeException() : super("Image is too large. Please select a smaller image.");
}

class ProfileInvalidImageFormatException extends ProfileException {
  const ProfileInvalidImageFormatException() : super("Unsupported image format. Please use JPEG, PNG, or WebP.");
}

class ProfileCameraPermissionDeniedException extends ProfileException {
  const ProfileCameraPermissionDeniedException() : super("Camera permission denied. Please enable camera access in app settings.");
}

class ProfileGalleryPermissionDeniedException extends ProfileException {
  const ProfileGalleryPermissionDeniedException() : super("Gallery permission denied. Please enable photo access in app settings.");
}

class ProfileCameraUnavailableException extends ProfileException {
  const ProfileCameraUnavailableException() : super("Camera is unavailable on this device.");
}

class ProfileGalleryUnavailableException extends ProfileException {
  const ProfileGalleryUnavailableException() : super("Gallery is unavailable on this device.");
}

class ProfileImageCompressionException extends ProfileException {
  const ProfileImageCompressionException() : super("Failed to compress selected image. Please try another image.");
}


class ProfileService {
  final ProfileRepository _repository;
  final FirebaseAuth _auth;
  final LocalProfileImageService _localImageService;

  ProfileService({ProfileRepository? repository, FirebaseAuth? auth, LocalProfileImageService? localImageService}) 
    : _repository = repository ?? ProfileRepositoryImpl(),
      _auth = auth ?? FirebaseAuth.instance,
      _localImageService = localImageService ?? LocalProfileImageService();

  Future<UserProfileModel> loadProfile({bool forceServerFetch = false}) async {
    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      debugPrint('[ProfileService] Waiting for auth state changes...');
      currentUser = await _auth.authStateChanges().first;
    }

    if (currentUser == null) {
      throw const ProfileNotAuthenticatedException();
    }

    final uid = currentUser.uid;
    debugPrint('[ProfileService] Loading profile for uid: $uid');

    try {
      await _repository.ensureProfileDocument(currentUser);
      await _repository.updateLastLogin(uid);
    } catch (e) {
      debugPrint('[ProfileService] Failed to ensure document or update login (likely offline): $e');
      // Continue anyway, fetchProfile handles offline gracefully
    }

    try {
      final profile = await _repository.fetchProfile(uid, forceServerFetch: forceServerFetch);
      final localPath = await _localImageService.getProfilePicturePath(uid);
      if (localPath != null) {
        return profile.copyWith(localAvatarPath: localPath);
      }
      return profile;
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        throw const ProfileFirestoreUnavailableException();
      } else if (e.code == 'permission-denied') {
        throw const ProfileAuthExpiredException();
      }
      throw const ProfileNetworkException();
    } catch (e) {
      throw const ProfileDataCorruptedException();
    }
  }

  Future<UserProfileModel> updateProfile(String uid, {required String displayName, String? phoneNumber}) async {
    if (uid.isEmpty) {
      throw const ProfileNotAuthenticatedException();
    }
    
    if (_auth.currentUser == null) {
      throw const ProfileAuthExpiredException();
    }
    
    await _repository.updateProfileFields(uid, displayName: displayName, phoneNumber: phoneNumber);
    
    debugPrint('[ProfileService] Profile updated for uid: $uid');
    
    try {
      final profile = await _repository.fetchProfile(uid, forceServerFetch: false);
      final localPath = await _localImageService.getProfilePicturePath(uid);
      if (localPath != null) {
        return profile.copyWith(localAvatarPath: localPath);
      }
      return profile;
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        throw const ProfileFirestoreUnavailableException();
      } else if (e.code == 'permission-denied') {
        throw const ProfileAuthExpiredException();
      }
      throw const ProfileNetworkException();
    } catch (e) {
      throw const ProfileDataCorruptedException();
    }
  }

  Future<UserProfileModel> updateFullProfile(
    String uid, {
    required String displayName,
    String? phoneNumber,
    String? photoURL,       
    String? newLocalImagePath,    
    String? gender,         
    String? bloodGroup,     
    String? medicalNotes,
    bool removePhoto = false,
  }) async {
    if (uid.isEmpty) {
      throw const ProfileNotAuthenticatedException();
    }
    
    if (_auth.currentUser == null) {
      throw const ProfileAuthExpiredException();
    }

    if (removePhoto) {
      try {
        await _localImageService.deleteProfilePicture(uid);
      } catch (e) {
        debugPrint('[ProfileService] Failed to remove local picture: $e');
      }
    } else if (newLocalImagePath != null) {
      try {
        await _localImageService.saveProfilePicture(uid, newLocalImagePath);
      } catch (e) {
        debugPrint('[ProfileService] Failed to save local picture: $e');
        // Let it proceed to update text fields even if picture fails
      }
    }
    
    await _repository.updateProfileFields(
      uid, 
      displayName: displayName, 
      phoneNumber: phoneNumber,
      photoURL: removePhoto ? null : photoURL,
    );
    
    await _repository.updateExtendedFields(
      uid,
      gender: gender,
      bloodGroup: bloodGroup,
      medicalNotes: medicalNotes,
    );
    
    debugPrint('[ProfileService] Profile fully updated for uid: $uid');
    
    try {
      final profile = await _repository.fetchProfile(uid, forceServerFetch: false);
      final localPath = await _localImageService.getProfilePicturePath(uid);
      if (localPath != null) {
        return profile.copyWith(localAvatarPath: localPath);
      }
      return profile;
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        throw const ProfileFirestoreUnavailableException();
      } else if (e.code == 'permission-denied') {
        throw const ProfileAuthExpiredException();
      }
      throw const ProfileNetworkException();
    } catch (e) {
      throw const ProfileDataCorruptedException();
    }
  }
}
