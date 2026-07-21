import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile_model.dart';
import '../repositories/profile_repository.dart';
import '../repositories/profile_repository_impl.dart';

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

class ProfileService {
  final ProfileRepository _repository;
  final FirebaseAuth _auth;

  ProfileService({ProfileRepository? repository, FirebaseAuth? auth}) 
    : _repository = repository ?? ProfileRepositoryImpl(),
      _auth = auth ?? FirebaseAuth.instance;

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
      return await _repository.fetchProfile(uid, forceServerFetch: forceServerFetch);
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
