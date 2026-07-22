import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
  static _BadgeVisual resolve(BuildContext context, String id) {
    final theme = Theme.of(context);
    final statusColors = theme.extension<AppStatusColors>();
    
    switch (id) {
      case 'verified':
        return _BadgeVisual(
          label: 'Verified',
          backgroundColor: statusColors?.success.withValues(alpha: 0.1) ?? const Color(0xFFDCFCE7),
          textColor: statusColors?.success ?? const Color(0xFF166534),
        );
      case 'premium':
        return _BadgeVisual(
          label: 'Premium',
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          textColor: theme.colorScheme.primary,
        );
      case 'priority':
        return _BadgeVisual(
          label: 'Priority',
          backgroundColor: statusColors?.warning.withValues(alpha: 0.1) ?? const Color(0xFFFEF3C7),
          textColor: statusColors?.warning ?? const Color(0xFF92400E),
        );
      case 'volunteer':
        return _BadgeVisual(
          label: 'Volunteer',
          backgroundColor: statusColors?.info.withValues(alpha: 0.1) ?? const Color(0xFFDBEAFE),
          textColor: statusColors?.info ?? const Color(0xFF1E40AF),
        );
      case 'administrator':
        return _BadgeVisual(
          label: 'Admin',
          backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
          textColor: theme.colorScheme.error,
        );
      default:
        return _BadgeVisual(
          label: id,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          textColor: theme.colorScheme.onSurfaceVariant,
        );
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
    final visual = _BadgeResolver.resolve(context, badgeId);

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
