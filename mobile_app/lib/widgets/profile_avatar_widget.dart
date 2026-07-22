import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';

class ProfileAvatarWidget extends StatelessWidget {
  final UserProfileModel profile;
  final double radius;
  final String? localFilePath;

  const ProfileAvatarWidget({
    super.key,
    required this.profile,
    this.radius = 48.0,
    this.localFilePath,
  });

  @override
  Widget build(BuildContext context) {
    final String? effectiveLocalPath = localFilePath ?? profile.localAvatarPath;

    if (effectiveLocalPath != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: ClipOval(
          child: Image.file(
            File(effectiveLocalPath),
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildInitialsOrIcon(context);
            },
          ),
        ),
      );
    }

    // Priority 2: Network image
    if (profile.photoURL != null && profile.photoURL!.isNotEmpty && (profile.photoURL!.startsWith('http://') || profile.photoURL!.startsWith('https://'))) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: ClipOval(
          child: Image.network(
            profile.photoURL!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        (loadingProgress.expectedTotalBytes ?? 1)
                    : null,
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              );
            },
            errorBuilder: (context, error, stackTrace) {
              // Priority 4: Error fallback to Priority 2 or 3
              return _buildInitialsOrIcon(context);
            },
          ),
        ),
      );
    }

    return _buildInitialsOrIcon(context);
  }

  Widget _buildInitialsOrIcon(BuildContext context) {
    final initials = profile.initials;
    final bool hasValidInitials = initials != '?' && initials.isNotEmpty;
    final theme = Theme.of(context);

    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: hasValidInitials
          // Priority 2: Initials
          ? Text(
              initials,
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            )
          // Priority 3: Default icon
          : Icon(
              Icons.person_rounded,
              size: radius * 1.2,
              color: theme.colorScheme.onPrimaryContainer,
            ),
    );
  }
}
