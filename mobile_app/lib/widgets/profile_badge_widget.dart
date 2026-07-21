import 'package:flutter/material.dart';

class _BadgeVisual {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _BadgeVisual({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });
}

class _BadgeResolver {
  static _BadgeVisual resolve(String id) {
    switch (id) {
      case 'verified':
        return const _BadgeVisual(label: 'Verified', backgroundColor: Color(0xFFDCFCE7), textColor: Color(0xFF166534));
      case 'premium':
        return const _BadgeVisual(label: 'Premium', backgroundColor: Color(0xFFEDE9FE), textColor: Color(0xFF5B21B6));
      case 'priority':
        return const _BadgeVisual(label: 'Priority', backgroundColor: Color(0xFFFEF3C7), textColor: Color(0xFF92400E));
      case 'volunteer':
        return const _BadgeVisual(label: 'Volunteer', backgroundColor: Color(0xFFDBEAFE), textColor: Color(0xFF1E40AF));
      case 'administrator':
        return const _BadgeVisual(label: 'Admin', backgroundColor: Color(0xFFFEE2E2), textColor: Color(0xFF991B1B));
      default:
        return _BadgeVisual(label: id, backgroundColor: const Color(0xFFF3F4F6), textColor: const Color(0xFF374151));
    }
  }
}

class ProfileBadgeWidget extends StatelessWidget {
  final String badgeId;

  const ProfileBadgeWidget({
    super.key,
    required this.badgeId,
  });

  @override
  Widget build(BuildContext context) {
    final visual = _BadgeResolver.resolve(badgeId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: visual.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        visual.label,
        style: TextStyle(
          color: visual.textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
