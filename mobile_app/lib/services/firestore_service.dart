import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createUserProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (userDoc.exists) {
      return;
    }

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'displayName': user.displayName ?? 'New User',
      'email': user.email ?? '',
      'phoneNumber': user.phoneNumber,
      'photoURL': user.photoURL,
      'isVerified': user.emailVerified,
      'accountCreated': user.metadata.creationTime != null ? Timestamp.fromDate(user.metadata.creationTime!) : null,
      'lastLogin': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'badges': user.emailVerified ? ['verified'] : [],
      'emergencyMode': false,
      'profileCompleted': false,
    });
  }
}
