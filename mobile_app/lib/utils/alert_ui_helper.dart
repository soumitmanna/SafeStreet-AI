import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Status colour
// ---------------------------------------------------------------------------

/// Returns the display colour for a given Firestore alert [status] string.
///
/// Uses the [AppStatusColors] theme extension for theme-aware colors.
/// Known values: 'active', 'accepted', 'resolved'.
Color alertStatusColor(BuildContext context, String status) {
  final statusColors = Theme.of(context).extension<AppStatusColors>();
  switch (status) {
    case 'active':
      return statusColors?.warning ?? const Color(0xFFFB923C);
    case 'accepted':
      return Theme.of(context).colorScheme.primary;
    case 'resolved':
      return statusColors?.success ?? const Color(0xFF22C55E);
    default:
      return statusColors?.info ?? const Color(0xFF0EA5E9);
  }
}

// ---------------------------------------------------------------------------
// Status icon
// ---------------------------------------------------------------------------

/// Returns a representative [IconData] for a given Firestore alert [status].
IconData alertStatusIcon(String status) {
  switch (status) {
    case 'active':
      return Icons.warning_rounded;
    case 'accepted':
      return Icons.shield_rounded;
    case 'resolved':
      return Icons.check_circle_rounded;
    default:
      return Icons.location_on_rounded;
  }
}

// ---------------------------------------------------------------------------
// Relative time
// ---------------------------------------------------------------------------

/// Returns a human-readable relative time string from [createdAt].
///
/// Uses plain Dart [Duration] arithmetic — no external package required.
String alertRelativeTime(DateTime? createdAt) {
  if (createdAt == null) return 'Just now';
  final diff = DateTime.now().difference(createdAt);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} min ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return '$h ${h == 1 ? 'hr' : 'hrs'} ago';
  }
  final d = diff.inDays;
  if (d == 1) return 'Yesterday';
  return '$d days ago';
}

// ---------------------------------------------------------------------------
// Full timestamp (intl)
// ---------------------------------------------------------------------------

/// Returns a formatted full date-time string.
///
/// Example: "3 Jul 2026 · 09:45 AM"
///
/// Uses [intl] which is already declared in pubspec.yaml.
/// Falls back to a dash when [timestamp] is null (e.g. pending
/// server confirmation of a just-created alert).
String alertFormattedTimestamp(DateTime? timestamp) {
  if (timestamp == null) return '—';
  return DateFormat("d MMM yyyy '·' hh:mm a").format(timestamp.toLocal());
}

// ---------------------------------------------------------------------------
// GPS coordinates
// ---------------------------------------------------------------------------

/// Returns a formatted GPS coordinate string.
///
/// Example: "22.572600, 88.363900"
String alertFormattedCoords(double latitude, double longitude) {
  return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}
