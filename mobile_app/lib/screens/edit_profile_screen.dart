import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/edit_profile_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/user_profile_model.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
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
        final isBusy = isSaving;

        return PopScope(
          canPop: !isBusy,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Edit Profile'),
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: isBusy ? null : _handleCancel,
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAvatarSection(context, state),
                    const SizedBox(height: 28),
                    _buildFormSection(context, state),
                    const SizedBox(height: 28),
                    _buildEmergencyInformationSection(context, state),
                    const SizedBox(height: 16),
                    if (isSaving)
                      const LinearProgressIndicator(),
                    if (state is EditProfileOffline)
                      _buildOfflineBanner(context),
                    if (state is EditProfileError)
                      _buildErrorBanner(context, state),
                    const SizedBox(height: 20),
                    _buildActionButtons(context, isBusy, state),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarSection(BuildContext context, EditProfileState state) {
    final theme = Theme.of(context);
    final bool showRemovePhoto = widget.profile.hasAvatar && !_controller.removePhotoOnSave && _controller.previewFilePath == null;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            ProfileAvatarWidget(
              profile: _controller.removePhotoOnSave ? widget.profile.withoutPhoto() : widget.profile,
              radius: 56,
              localFilePath: _controller.previewFilePath,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _showImageSourceBottomSheet(context),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.onSurface,
                  child: Icon(Icons.camera_alt_rounded, size: 18, color: theme.colorScheme.surface),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (state is EditProfilePreviewing)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.extension<AppStatusColors>()?.info.withValues(alpha: 0.1) ?? theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: theme.extension<AppStatusColors>()?.info ?? theme.colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "New photo selected. Tap 'Save Changes' to apply.",
                    style: TextStyle(fontSize: 12, color: theme.extension<AppStatusColors>()?.info ?? theme.colorScheme.primary),
                  ),
                ),
                TextButton(
                  onPressed: _controller.discardImagePreview,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text("Discard"),
                ),
              ],
            ),
          )
        else if (showRemovePhoto)
          TextButton(
            onPressed: () => _showRemovePhotoConfirmation(context),
            child: Text('Remove Photo', style: TextStyle(color: theme.colorScheme.error)),
          ),
      ],
    );
  }

  void _showImageSourceBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _controller.pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _controller.pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close_rounded),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRemovePhotoConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Photo'),
        content: const Text('Are you sure you want to remove your profile picture?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _controller.markPhotoForRemoval();
            },
            child: Text('Remove', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection(BuildContext context, EditProfileState state) {
    final theme = Theme.of(context);
    Map<String, String>? fieldErrors;
    if (state is EditProfileValidationError) {
      fieldErrors = state.fieldErrors;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
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
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Phone Number (optional)',
              hintText: '+1 555 000 0000',
              errorText: fieldErrors?['phoneNumber'],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // ignore: deprecated_member_use
          DropdownButtonFormField<String?>(
            initialValue: _controller.selectedGender,
            decoration: InputDecoration(
              labelText: 'Gender (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Prefer not to say')),
              ...ProfileGender.values.map((g) => DropdownMenuItem(
                    value: g.toStorageString(),
                    child: Text(g.label),
                  )),
            ],
            onChanged: _controller.onGenderChanged,
          ),
          const SizedBox(height: 20),
          // ignore: deprecated_member_use
          DropdownButtonFormField<String?>(
            initialValue: _controller.selectedBloodGroup,
            decoration: InputDecoration(
              labelText: 'Blood Group (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Not specified')),
              ...ProfileBloodGroup.values.map((b) => DropdownMenuItem(
                    value: b.toStorageString(),
                    child: Text(b.label),
                  )),
            ],
            onChanged: _controller.onBloodGroupChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyInformationSection(BuildContext context, EditProfileState state) {
    final theme = Theme.of(context);
    Map<String, String>? fieldErrors;
    if (state is EditProfileValidationError) {
      fieldErrors = state.fieldErrors;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emergency Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _controller.medicalNotesController,
            keyboardType: TextInputType.multiline,
            maxLines: 5,
            maxLength: 500,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: 'Medical Notes (optional)',
              hintText: 'e.g. Diabetic, penicillin allergy, blood thinner medication...',
              helperText: 'Visible only to emergency responders.',
              errorText: fieldErrors?['medicalNotes'],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    final theme = Theme.of(context);
    final warningColor = theme.extension<AppStatusColors>()?.warning ?? theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warningColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: warningColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No internet connection. Your changes will sync when you reconnect.',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, EditProfileError state) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: errorColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline_rounded, color: errorColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.userMessage,
                  style: TextStyle(color: theme.colorScheme.onSurface),
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

  Widget _buildActionButtons(BuildContext context, bool isBusy, EditProfileState state) {
    final theme = Theme.of(context);
    final bool canSave = state is EditProfileIdle || state is EditProfileEditing || state is EditProfilePreviewing;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (canSave && !isBusy) ? _handleSave : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              disabledBackgroundColor: theme.colorScheme.primary.withValues(alpha: 0.5),
              disabledForegroundColor: theme.colorScheme.onPrimary.withValues(alpha: 0.5),
              foregroundColor: theme.colorScheme.onPrimary,
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
            onPressed: isBusy ? null : _handleCancel,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.dividerColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
