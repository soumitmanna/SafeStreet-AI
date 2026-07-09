import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns the current user's emergency contacts collection
  CollectionReference<Map<String, dynamic>> _contactsCollection(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('emergencyContacts');
  }

  /// Add Emergency Contact
  Future<void> addContact({
    required String name,
    required String phone,
    required String relation,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    await _contactsCollection(user.uid).add({
      'name': name,
      'phone': phone,
      'relation': relation,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get Emergency Contacts
  Stream<QuerySnapshot<Map<String, dynamic>>> getContacts() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    return _contactsCollection(user.uid)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  /// Fetch emergency contacts once for SOS notifications.
  Future<List<Map<String, dynamic>>> getContactList() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    final snapshot = await _contactsCollection(user.uid).get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'docId': doc.id,
        'name': (data['name'] ?? '').toString(),
        'phone': (data['phone'] ?? '').toString(),
        'relation': (data['relation'] ?? '').toString(),
      };
    }).toList();
  }

  /// Update Emergency Contact
  Future<void> updateContact({
    required String docId,
    required String name,
    required String phone,
    required String relation,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    await _contactsCollection(user.uid).doc(docId).update({
      'name': name,
      'phone': phone,
      'relation': relation,
    });
  }

  /// Delete Emergency Contact
  Future<void> deleteContact(String docId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    await _contactsCollection(user.uid).doc(docId).delete();
  }

  /// Check if a phone number already exists.
  ///
  /// [excludeDocId] is used while editing a contact.
  /// The contact being edited will be ignored during the duplicate check.
  Future<bool> phoneExists({
    required String phone,
    String? excludeDocId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    final querySnapshot = await _contactsCollection(user.uid)
        .where('phone', isEqualTo: phone)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return false;
    }

    // Editing an existing contact:
    // Ignore the current document while checking duplicates.
    if (excludeDocId != null) {
      for (final doc in querySnapshot.docs) {
        if (doc.id != excludeDocId) {
          return true;
        }
      }
      return false;
    }

    // Adding a new contact:
    // Any matching phone number is a duplicate.
    return true;
  }
}