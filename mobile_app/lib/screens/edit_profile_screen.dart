import 'package:flutter/material.dart';
import '../controllers/edit_profile_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/user_profile_model.dart';
import '../services/profile_service.dart';
import '../widgets/profile_avatar_widget.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfileModel profile;
  final ProfileController profileController;

  const EditProfileScreen({
    super.key,
    required this.profile,
    required this.profileController,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final EditProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EditProfileController(
      initialProfile: widget.profile,
      service: ProfileService(),
      profileController: widget.profileController,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() async {
    await _controller.save();
    
    if (!mounted) return;

    final state = _controller.state;
    if (state is EditProfileSaved) {
      Navigator.pop(context, true);
    } else if (state is EditProfileIdle) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes to save')),
      );
    }
  }

  void _handleCancel() {
    final bool wasOffline = _controller.state is EditProfileOffline;
    _controller.cancel();
    Navigator.pop(context, wasOffline);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;
        final isSaving = state is EditProfileSaving;

        return PopScope(
          canPop: !isSaving,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: const Text('Edit Profile'),
              backgroundColor: Colors.white,
              elevation: 0,
              foregroundColor: Colors.black87,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: isSaving ? null : _handleCancel,
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAvatarSection(),
                    const SizedBox(height: 28),
                    _buildFormSection(state),
                    const SizedBox(height: 16),
                    if (isSaving)
                      const LinearProgressIndicator(),
                    if (state is EditProfileOffline)
                      _buildOfflineBanner(),
                    if (state is EditProfileError)
                      _buildErrorBanner(state),
                    const SizedBox(height: 20),
                    _buildActionButtons(isSaving, state),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        ProfileAvatarWidget(
          profile: widget.profile,
          radius: 56,
        ),
        const SizedBox(height: 12),
        const Text(
          'Profile picture editing coming soon',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black38,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection(EditProfileState state) {
    Map<String, String>? fieldErrors;
    if (state is EditProfileValidationError) {
      fieldErrors = state.fieldErrors;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _controller.displayNameController,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Display Name',
              hintText: 'Enter your full name',
              errorText: fieldErrors?['displayName'],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _controller.phoneNumberController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Phone Number (optional)',
              hintText: '+1 555 000 0000',
              errorText: fieldErrors?['phoneNumber'],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.amber.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No internet connection. Your changes will sync when you reconnect.',
              style: TextStyle(color: Colors.amber.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(EditProfileError state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.red.shade800),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.userMessage,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _controller.retry,
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isSaving, EditProfileState state) {
    final bool canSave = state is EditProfileIdle || state is EditProfileEditing;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (canSave && !isSaving) ? _handleSave : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF000000),
              disabledBackgroundColor: const Color(0xFF000000).withValues(alpha: 0.5),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Save Changes',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: isSaving ? null : _handleCancel,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.black12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
