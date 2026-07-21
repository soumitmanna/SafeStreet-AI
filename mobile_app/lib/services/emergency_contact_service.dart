import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/emergency_contact_model.dart';
import '../repositories/emergency_contact_repository.dart';
import '../repositories/emergency_contact_repository_impl.dart';

abstract class ContactException implements Exception {
  final String message;
  const ContactException(this.message);
}

class ContactNotAuthenticatedException extends ContactException {
  const ContactNotAuthenticatedException() : super("Session expired. Please log in again.");
}

class ContactNetworkException extends ContactException {
  const ContactNetworkException() : super("No internet connection.");
}

class ContactFirestoreUnavailableException extends ContactException {
  const ContactFirestoreUnavailableException() : super("Service temporarily unavailable.");
}

class ContactValidationException extends ContactException {
  final String field;
  final String reason;
  const ContactValidationException(this.field, this.reason) : super(reason);
}

class ContactDuplicatePhoneException extends ContactException {
  const ContactDuplicatePhoneException() : super("This phone number is already saved.");
}

class ContactMaxLimitReachedException extends ContactException {
  const ContactMaxLimitReachedException() : super("You can save up to 10 emergency contacts.");
}

class ContactLaunchException extends ContactException {
  const ContactLaunchException(String type) : super("Could not launch $type. Please try manually.");
}

class EmergencyContactService {
  static final EmergencyContactService _instance = EmergencyContactService._internal();

  factory EmergencyContactService({EmergencyContactRepository? repository, FirebaseAuth? auth}) {
    return _instance;
  }

  final EmergencyContactRepository _repository;
  final FirebaseAuth _auth;

  // In-memory cache for SOS integration
  List<EmergencyContactModel>? _cachedContacts;
  DateTime? _cacheTimestamp;
  static const _cacheTtl = Duration(minutes: 5);

  EmergencyContactService._internal({EmergencyContactRepository? repository, FirebaseAuth? auth})
      : _repository = repository ?? EmergencyContactRepositoryImpl(),
        _auth = auth ?? FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw const ContactNotAuthenticatedException();
    return user.uid;
  }

  void _invalidateCache() {
    _cachedContacts = null;
    _cacheTimestamp = null;
  }

  Stream<List<EmergencyContactModel>> streamContacts() {
    developer.log('Loading contacts...');
    return _repository.streamContacts(_uid);
  }

  Future<List<EmergencyContactModel>> loadContacts() async {
    try {
      final contacts = await _repository.fetchAll(_uid);
      _cachedContacts = contacts;
      _cacheTimestamp = DateTime.now();
      return contacts;
    } catch (e) {
      throw const ContactFirestoreUnavailableException();
    }
  }

  Future<List<EmergencyContactModel>> getContactsForSOS() async {
    if (_cachedContacts != null && _cacheTimestamp != null) {
      if (DateTime.now().difference(_cacheTimestamp!) < _cacheTtl) {
        return _cachedContacts!;
      }
    }
    return await loadContacts();
  }

  Future<void> addContact(EmergencyContactModel draft) async {
    final uid = _uid;

    if (draft.displayName.trim().length < 2 || draft.displayName.trim().length > 60) {
      throw const ContactValidationException('displayName', 'Name must be 2-60 letters.');
    }

    final exists = await _repository.phoneExists(uid, draft.phone);
    if (exists) {
      throw const ContactDuplicatePhoneException();
    }

    final currentContacts = await _repository.fetchAll(uid);
    if (currentContacts.length >= 10) {
      throw const ContactMaxLimitReachedException();
    }

    // If it's the first contact, make it primary
    final isFirst = currentContacts.isEmpty;
    final contactToAdd = isFirst ? draft.copyWith(isPrimary: true) : draft;

    await _repository.add(uid, contactToAdd);
    
    // If added as primary but not the first one (shouldn't happen with UI logic, but just in case)
    if (contactToAdd.isPrimary && !isFirst) {
      final oldPrimary = currentContacts.cast<EmergencyContactModel?>().firstWhere((c) => c?.isPrimary == true, orElse: () => null);
      if (oldPrimary != null) {
         // Need ID for new primary, but we just added it. Best to rely on UI setting it primary *after* creation or doing a fetch.
         // For simplicity, we just invalidate cache.
      }
    }

    _invalidateCache();
  }

  Future<void> updateContact(EmergencyContactModel updated) async {
    final uid = _uid;

    if (updated.displayName.trim().length < 2 || updated.displayName.trim().length > 60) {
      throw const ContactValidationException('displayName', 'Name must be 2-60 letters.');
    }

    final exists = await _repository.phoneExists(uid, updated.phone, excludeId: updated.id);
    if (exists) {
      throw const ContactDuplicatePhoneException();
    }

    await _repository.update(uid, updated);
    _invalidateCache();
  }

  Future<void> deleteContact(String contactId) async {
    final uid = _uid;
    final currentContacts = await _repository.fetchAll(uid);
    final contactToDelete = currentContacts.cast<EmergencyContactModel?>().firstWhere((c) => c?.id == contactId, orElse: () => null);

    await _repository.delete(uid, contactId);

    // If the deleted contact was primary, promote the next one
    if (contactToDelete != null && contactToDelete.isPrimary) {
      final remaining = currentContacts.where((c) => c.id != contactId).toList();
      if (remaining.isNotEmpty) {
        // Promote the first available one (sorted by sortOrder)
        await _repository.setPrimary(uid, remaining.first.id, null);
      }
    }

    _invalidateCache();
  }

  Future<void> setPrimary(String newPrimaryId) async {
    final uid = _uid;
    final currentContacts = await _repository.fetchAll(uid);
    final oldPrimary = currentContacts.cast<EmergencyContactModel?>().firstWhere((c) => c?.isPrimary == true, orElse: () => null);

    if (oldPrimary?.id == newPrimaryId) return; // Already primary

    await _repository.setPrimary(uid, newPrimaryId, oldPrimary?.id);
    _invalidateCache();
  }

  Future<void> reorderContacts(List<EmergencyContactModel> ordered) async {
    final uid = _uid;
    await _repository.batchUpdateSortOrder(uid, ordered);
    _invalidateCache();
  }

  Future<void> callContact(EmergencyContactModel contact) async {
    developer.log('Launching call... ${contact.displayName} (${contact.phone})');
    final cleanPhone = contact.phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(uri);
        if (launched) {
          developer.log('Call launched successfully.');
        } else {
          developer.log('Launch failed.');
          throw const ContactLaunchException('phone call');
        }
      } else {
        developer.log('Launch failed.');
        throw const ContactLaunchException('phone call');
      }
    } catch (e) {
      developer.log('Launch failed.');
      throw const ContactLaunchException('phone call');
    }
  }

  Future<void> smsContact(EmergencyContactModel contact) async {
    final cleanPhone = contact.phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('sms:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw const ContactLaunchException('SMS');
    }
  }
}
