import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../models/emergency_contact_model.dart';
import '../services/emergency_contact_service.dart';

enum ContactsState { initial, loading, loaded, empty, error }

class EmergencyContactsController extends ChangeNotifier {
  final EmergencyContactService _service;
  StreamSubscription<List<EmergencyContactModel>>? _subscription;

  ContactsState _state = ContactsState.initial;
  ContactsState get state => _state;

  List<EmergencyContactModel> _contacts = [];
  List<EmergencyContactModel> _filteredContacts = [];
  List<EmergencyContactModel> get contacts => _searchQuery.isEmpty ? _contacts : _filteredContacts;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  EmergencyContactsController({EmergencyContactService? service})
      : _service = service ?? EmergencyContactService();

  void init() {
    _setState(ContactsState.loading);
    developer.log('[EmergencyContactsController] Subscribed to contact stream.');

    _subscription?.cancel();
    _subscription = _service.streamContacts().listen(
      (contactsList) {
        developer.log('[EmergencyContactsController] Firestore snapshot received.');
        developer.log('[EmergencyContactsController] Contacts count: ${contactsList.length}');
        _contacts = contactsList;
        _applySearch();
        
        final primary = contactsList.where((c) => c.isPrimary).firstOrNull;
        if (primary != null) {
          developer.log('[EmergencyContactsController] Primary contact: ${primary.displayName}');
        } else {
          developer.log('[EmergencyContactsController] Primary contact: None');
        }

        _setState(_contacts.isEmpty ? ContactsState.empty : ContactsState.loaded);
        developer.log('[EmergencyContactsController] Stream updated.');
      },
      onError: (error) {
        developer.log('[EmergencyContactsController] Stream error: $error');
        _errorMessage = "An error occurred while loading contacts.";
        _setState(ContactsState.error);
      },
    );
  }

  @override
  void dispose() {
    developer.log('[EmergencyContactsController] Disposing and canceling stream subscription.');
    _subscription?.cancel();
    super.dispose();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    _applySearch();
    notifyListeners();
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredContacts = _contacts;
    } else {
      _filteredContacts = _contacts.where((c) {
        return c.displayName.toLowerCase().contains(_searchQuery) ||
               c.phone.contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> addContact(EmergencyContactModel draft) async {
    await _performMutation(() async {
      await _service.addContact(draft);
      developer.log('[EmergencyContactsController] Add completed.');
    });
  }

  Future<void> updateContact(EmergencyContactModel updated) async {
    await _performMutation(() async {
      await _service.updateContact(updated);
      developer.log('[EmergencyContactsController] Edit completed.');
    });
  }

  Future<void> deleteContact(String contactId) async {
    await _performMutation(() async {
      await _service.deleteContact(contactId);
      developer.log('[EmergencyContactsController] Delete completed.');
    });
  }

  Future<void> setPrimary(String contactId) async {
    await _performMutation(() async {
      await _service.setPrimary(contactId);
      developer.log('[EmergencyContactsController] Primary updated.');
    });
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || newIndex < 0 || oldIndex >= _contacts.length || newIndex > _contacts.length) return;
    
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    if (oldIndex == newIndex) return;

    await _performMutation(() async {
      // We still need to calculate the new order list to send to the service
      final mutableList = List<EmergencyContactModel>.from(_contacts);
      final item = mutableList.removeAt(oldIndex);
      mutableList.insert(newIndex, item);
      
      // Update sortOrder on the local items for the service call
      for (int i = 0; i < mutableList.length; i++) {
        mutableList[i] = mutableList[i].copyWith(sortOrder: i);
      }
      
      await _service.reorderContacts(mutableList);
      developer.log('[EmergencyContactsController] Reorder completed.');
    });
  }

  Future<void> callContact(EmergencyContactModel contact) async {
    try {
      await _service.callContact(contact);
    } on ContactException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<void> smsContact(EmergencyContactModel contact) async {
    try {
      await _service.smsContact(contact);
    } on ContactException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setState(ContactsState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> _performMutation(Future<void> Function() action) async {
    if (_isBusy) return;
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
    } on ContactException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = "An unexpected error occurred.";
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}
