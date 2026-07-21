import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emergency_contact_model.dart';
import 'emergency_contact_repository.dart';

class EmergencyContactRepositoryImpl implements EmergencyContactRepository {
  static final EmergencyContactRepositoryImpl _instance = EmergencyContactRepositoryImpl._internal();

  factory EmergencyContactRepositoryImpl() {
    return _instance;
  }

  EmergencyContactRepositoryImpl._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _contactsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('emergencyContacts');
  }

  @override
  Future<List<EmergencyContactModel>> fetchAll(String uid) async {
    final snapshot = await _contactsRef(uid).orderBy('sortOrder', descending: false).get();
    return snapshot.docs.map((doc) => EmergencyContactModel.fromFirestore(doc)).toList();
  }

  @override
  Stream<List<EmergencyContactModel>> streamContacts(String uid) {
    return _contactsRef(uid)
        .orderBy('sortOrder', descending: false)
        .snapshots()
        .map((snapshot) {
      developer.log('Firestore snapshot received.');
      developer.log('Number of contacts: ${snapshot.docs.length}');

      final contacts = snapshot.docs
          .map((doc) => EmergencyContactModel.fromFirestore(doc))
          .toList();

      final primary = contacts.cast<EmergencyContactModel?>().firstWhere(
        (c) => c?.isPrimary == true,
        orElse: () => null,
      );
      developer.log('Primary contact: ${primary?.displayName ?? "None"}');

      return contacts;
    });
  }

  @override
  Future<void> add(String uid, EmergencyContactModel contact) async {
    await _contactsRef(uid).add({
      ...contact.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> update(String uid, EmergencyContactModel contact) async {
    await _contactsRef(uid).doc(contact.id).update(contact.toFirestore());
  }

  @override
  Future<void> delete(String uid, String contactId) async {
    await _contactsRef(uid).doc(contactId).delete();
  }

  @override
  Future<void> setPrimary(String uid, String newPrimaryId, String? oldPrimaryId) async {
    final batch = _firestore.batch();
    
    if (oldPrimaryId != null && oldPrimaryId != newPrimaryId) {
      batch.update(_contactsRef(uid).doc(oldPrimaryId), {
        'isPrimary': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    batch.update(_contactsRef(uid).doc(newPrimaryId), {
      'isPrimary': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  @override
  Future<void> batchUpdateSortOrder(String uid, List<EmergencyContactModel> ordered) async {
    final batch = _firestore.batch();
    
    for (int i = 0; i < ordered.length; i++) {
      batch.update(_contactsRef(uid).doc(ordered[i].id), {
        'sortOrder': i,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  @override
  Future<bool> phoneExists(String uid, String phone, {String? excludeId}) async {
    final snapshot = await _contactsRef(uid).where('phone', isEqualTo: phone).get();
    
    if (snapshot.docs.isEmpty) return false;

    if (excludeId != null) {
      return snapshot.docs.any((doc) => doc.id != excludeId);
    }
    
    return true;
  }
}
