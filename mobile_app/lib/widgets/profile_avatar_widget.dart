import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';

class ProfileAvatarWidget extends StatelessWidget {
  final UserProfileModel profile;
  final double radius;

  const ProfileAvatarWidget({
    super.key,
    required this.profile,
    this.radius = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    // Priority 1: Network image
    if (profile.hasAvatar && (profile.photoURL!.startsWith('http://') || profile.photoURL!.startsWith('https://'))) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFE0E7FF),
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
                color: const Color(0xFF3730A3),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              // Priority 4: Error fallback to Priority 2 or 3
              return _buildInitialsOrIcon();
            },
          ),
        ),
      );
    }

    return _buildInitialsOrIcon();
  }

  Widget _buildInitialsOrIcon() {
    final initials = profile.initials;
    final bool hasValidInitials = initials != '?' && initials.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE0E7FF),
      child: hasValidInitials
          // Priority 2: Initials
          ? Text(
              initials,
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3730A3),
              ),
            )
          // Priority 3: Default icon
          : Icon(
              Icons.person_rounded,
              size: radius * 1.2,
              color: const Color(0xFF3730A3),
            ),
    );
  }
}
