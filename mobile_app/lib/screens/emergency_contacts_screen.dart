import 'package:flutter/material.dart';
import '../controllers/emergency_contacts_controller.dart';
import '../models/emergency_contact_model.dart';
import '../widgets/emergency_contact_card.dart';
import '../widgets/emergency_contact_form_sheet.dart';
import '../widgets/emergency_contacts_empty_state.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  late final EmergencyContactsController _controller;
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = EmergencyContactsController();
    _controller.init();
    _searchController.addListener(() {
      _controller.setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showFormSheet([EmergencyContactModel? contact]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => EmergencyContactFormSheet(
        initialContact: contact,
        onSave: (draft) async {
          if (contact == null) {
            await _controller.addContact(draft);
          } else {
            await _controller.updateContact(draft);
          }
        },
      ),
    );
  }

  void _confirmDelete(EmergencyContactModel contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to remove ${contact.displayName} from your emergency contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _controller.deleteContact(contact.id);
            },
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: _isSearchVisible
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search contacts...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 18),
              )
            : const Text('Emergency Contacts'),
        actions: [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                if (_isSearchVisible) {
                  _searchController.clear();
                }
                _isSearchVisible = !_isSearchVisible;
              });
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Stack(
            children: [
              _buildBody(),
              if (_controller.errorMessage != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildErrorBanner(),
                ),
            ],
          );
        },
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.state == ContactsState.initial || _controller.state == ContactsState.loading) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: _controller.isBusy ? null : () => _showFormSheet(),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Contact', style: TextStyle(fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    switch (_controller.state) {
      case ContactsState.initial:
      case ContactsState.loading:
        return Center(
          child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
        );
      
      case ContactsState.empty:
        if (_controller.searchQuery.isNotEmpty) {
          return _buildNoSearchResults();
        }
        return EmergencyContactsEmptyState(onAddPressed: () => _showFormSheet());
      
      case ContactsState.loaded:
        if (_controller.contacts.isEmpty) {
          return _buildNoSearchResults();
        }
        return _buildContactsList();
        
      case ContactsState.error:
        if (_controller.contacts.isNotEmpty) {
          return _buildContactsList(); // Show list with banner on top
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              const Text('Failed to load contacts.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _controller.init,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildNoSearchResults() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No contacts found for "${_controller.searchQuery}"',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88), // Bottom padding for FAB
      itemCount: _controller.contacts.length,
      onReorderItem: (oldIndex, newIndex) => _controller.reorder(oldIndex, newIndex),
      proxyDecorator: (child, index, animation) {
        return Material(
          color: Colors.transparent,
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final contact = _controller.contacts[index];
        return Padding(
          key: ValueKey(contact.id),
          padding: const EdgeInsets.only(bottom: 0),
          child: EmergencyContactCard(
            contact: contact,
            onCall: () => _controller.callContact(contact),
            onSms: () => _controller.smsContact(contact),
            onEdit: () => _showFormSheet(contact),
            onDelete: () => _confirmDelete(contact),
            onSetPrimary: () => _controller.setPrimary(contact.id),
          ),
        );
      },
    );
  }

  Widget _buildErrorBanner() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: theme.colorScheme.error,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: theme.colorScheme.onError, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _controller.errorMessage!,
                style: TextStyle(color: theme.colorScheme.onError, fontSize: 14),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded, color: theme.colorScheme.onError, size: 20),
              onPressed: _controller.clearError,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
