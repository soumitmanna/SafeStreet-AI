import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'profile_repository.dart';
import '../models/user_profile_model.dart';
import '../services/profile_service.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<UserProfileModel> fetchProfile(String uid, {bool forceServerFetch = false}) async {
    try {
      final source = forceServerFetch ? Source.server : Source.cache;
      
      debugPrint('[ProfileRepositoryImpl] Firestore read: users/$uid with source $source');
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get(GetOptions(source: source));
      
      if (!doc.exists && !forceServerFetch) {
        // If not found in cache, fallback to server
        debugPrint('[ProfileRepositoryImpl] Document not in cache, fetching from server');
        doc = await _firestore.collection('users').doc(uid).get(GetOptions(source: Source.server));
      }

      if (!doc.exists) {
        // Should have been created by ensureProfileDocument, but handle gracefully
        final user = _auth.currentUser;
        if (user != null && user.uid == uid) {
          debugPrint('[ProfileRepositoryImpl] Document missing, ensuring creation');
          await ensureProfileDocument(user);
          doc = await _firestore.collection('users').doc(uid).get(GetOptions(source: Source.server));
        }
      }

      debugPrint('[ProfileRepositoryImpl] Firestore read succeeded');
      return UserProfileModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      debugPrint('[ProfileRepositoryImpl] Firestore read failed: ${e.code} — ${e.message}');
      // Offline fallback
      final user = _auth.currentUser;
      if (user != null && user.uid == uid) {
        debugPrint('[ProfileRepositoryImpl] Using Auth fallback model (offline or Firestore unavailable)');
        return UserProfileModel.fromAuth(user);
      }
      rethrow;
    } catch (e) {
      debugPrint('[ProfileRepositoryImpl] Firestore read failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateLastLogin(String uid) async {
    await _firestore.collection('users').doc(uid).set({
      'lastLogin': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> ensureProfileDocument(User authUser) async {
    final docRef = _firestore.collection('users').doc(authUser.uid);
    
    // Try to get document, ignoring offline errors
    DocumentSnapshot? docSnapshot;
    try {
      docSnapshot = await docRef.get(GetOptions(source: Source.server));
    } catch (e) {
      try {
        docSnapshot = await docRef.get(GetOptions(source: Source.cache));
      } catch (e2) {
        // We will just proceed with creating/updating if offline cache fails
      }
    }

    if (docSnapshot == null || !docSnapshot.exists) {
      await docRef.set({
        'uid': authUser.uid,
        'displayName': authUser.displayName ?? 'User',
        'email': authUser.email ?? '',
        'phoneNumber': authUser.phoneNumber,
        'photoURL': authUser.photoURL,
        'isVerified': authUser.emailVerified,
        'accountCreated': authUser.metadata.creationTime != null ? Timestamp.fromDate(authUser.metadata.creationTime!) : null,
        'lastLogin': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'badges': authUser.emailVerified ? ['verified'] : [],
        'emergencyMode': false,
        'profileCompleted': false,
      });
    } else {
      final data = docSnapshot.data() as Map<String, dynamic>?;
      await docRef.set({
        'displayName': authUser.displayName ?? data?['displayName'] ?? 'User',
        'photoURL': authUser.photoURL ?? data?['photoURL'],
        'isVerified': authUser.emailVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<void> updateProfileFields(
    String uid, {
    required String displayName,
    String? phoneNumber,
    String? photoURL,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[ProfileRepositoryImpl] Firestore write: users/$uid — base profile fields');
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        debugPrint('[ProfileRepositoryImpl] Offline write queued for: users/$uid');
        throw const ProfileOfflineException();
      } else if (e.code == 'permission-denied') {
        throw const ProfileAuthExpiredException();
      }
      throw const ProfileFirestoreUnavailableException();
    } catch (e) {
      throw const ProfileFirestoreUnavailableException();
    }
  }

  @override
  Future<void> updateExtendedFields(
    String uid, {
    String? gender,
    String? bloodGroup,
    String? medicalNotes,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'gender': gender,
        'bloodGroup': bloodGroup,
        'medicalNotes': medicalNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[ProfileRepositoryImpl] Firestore write: users/$uid — extended fields');
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        debugPrint('[ProfileRepositoryImpl] Offline write queued for: users/$uid');
        throw const ProfileOfflineException();
      } else if (e.code == 'permission-denied') {
        throw const ProfileAuthExpiredException();
      }
      throw const ProfileFirestoreUnavailableException();
    } catch (e) {
      throw const ProfileFirestoreUnavailableException();
    }
  }
}
