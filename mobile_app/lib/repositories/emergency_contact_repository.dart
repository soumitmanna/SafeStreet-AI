import '../models/emergency_contact_model.dart';

abstract class EmergencyContactRepository {
  Future<List<EmergencyContactModel>> fetchAll(String uid);
  Stream<List<EmergencyContactModel>> streamContacts(String uid);
  Future<void> add(String uid, EmergencyContactModel contact);
  Future<void> update(String uid, EmergencyContactModel contact);
  Future<void> delete(String uid, String contactId);
  Future<void> setPrimary(String uid, String newPrimaryId, String? oldPrimaryId);
  Future<void> batchUpdateSortOrder(String uid, List<EmergencyContactModel> ordered);
  Future<bool> phoneExists(String uid, String phone, {String? excludeId});
}
