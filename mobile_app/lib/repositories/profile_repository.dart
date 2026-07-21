import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile_model.dart';

abstract class ProfileRepository {
  Future<UserProfileModel> fetchProfile(String uid, {bool forceServerFetch = false});
  Future<void> updateLastLogin(String uid);
  Future<void> ensureProfileDocument(User authUser);
  
  Future<void> updateProfileFields(
    String uid, {
    required String displayName,
    String? phoneNumber,
    String? photoURL,
  });

  Future<void> updateExtendedFields(
    String uid, {
    String? gender,
    String? bloodGroup,
    String? medicalNotes,
  });
}
