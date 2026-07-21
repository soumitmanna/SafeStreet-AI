import 'package:flutter/material.dart';
import '../models/emergency_contact_model.dart';

class EmergencyContactFormSheet extends StatefulWidget {
  final EmergencyContactModel? initialContact;
  final Future<void> Function(EmergencyContactModel) onSave;

  const EmergencyContactFormSheet({
    super.key,
    this.initialContact,
    required this.onSave,
  });

  @override
  State<EmergencyContactFormSheet> createState() => _EmergencyContactFormSheetState();
}

class _EmergencyContactFormSheetState extends State<EmergencyContactFormSheet> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _relationController;
  late final TextEditingController _emailController;
  
  bool _isPrimary = false;
  bool _isSaving = false;
  String? _errorMessage;
  bool _autoValidate = false;

  @override
  void initState() {
    super.initState();
    final c = widget.initialContact;
    _nameController = TextEditingController(text: c?.displayName ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _relationController = TextEditingController(text: c?.relationship ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _isPrimary = c?.isPrimary ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() {
      _autoValidate = true;
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final draft = EmergencyContactModel(
      id: widget.initialContact?.id ?? '',
      displayName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      relationship: _relationController.text.trim().isNotEmpty ? _relationController.text.trim() : null,
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      isPrimary: _isPrimary,
      sortOrder: widget.initialContact?.sortOrder ?? 0,
    );

    try {
      await widget.onSave(draft);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: _autoValidate ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.initialContact == null ? 'Add Emergency Contact' : 'Edit Contact',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              TextFormField(
                controller: _nameController,
                autofocus: widget.initialContact == null,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'Full Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                validator: (val) {
                  final v = val?.trim() ?? '';
                  if (v.isEmpty) return 'Name is required.';
                  if (v.length < 2 || v.length > 60) return 'Name must be 2–60 characters.';
                  if (!RegExp(r"^[a-zA-Z\s'\-]+$").hasMatch(v)) return 'Contains invalid characters.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+1 555 123 4567',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                validator: (val) {
                  final v = val?.trim() ?? '';
                  if (v.isEmpty) return 'Phone number is required.';
                  final digits = v.replaceAll(RegExp(r'[^\d]'), '');
                  if (!RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(v)) return 'Contains invalid characters.';
                  if (digits.length < 7 || digits.length > 15) return 'Must be 7-15 digits long.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _relationController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Relationship (Optional)',
                  hintText: 'e.g., Sister, Friend',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.family_restroom_rounded),
                ),
                validator: (val) {
                  if (val != null && val.trim().length > 40) return 'Max 40 characters.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Email Address (Optional)',
                  hintText: 'example@domain.com',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (val) {
                  final v = val?.trim() ?? '';
                  if (v.isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Set as Primary Contact'),
                subtitle: const Text('Will be called first during emergencies', style: TextStyle(fontSize: 12)),
                value: _isPrimary,
                onChanged: (val) => setState(() => _isPrimary = val),
                contentPadding: EdgeInsets.zero,
                activeTrackColor: const Color(0xFF3730A3),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.black54,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Save Contact',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
