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
      'email': user.email ?? '',
      'name': 'New User',
      'phone': '',
      'createdAt': FieldValue.serverTimestamp(),
      'emergencyMode': false,
      'profileCompleted': false,
    });
  }
}
