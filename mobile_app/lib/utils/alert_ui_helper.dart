// =============================================================
// SafeStreet
// Alert UI Helper
//
// Pure, stateless helper functions used by any screen that
// renders AlertModel data.
//
// Extracted from AlertsScreen (Phase 11.1) so that
// AlertDetailsScreen (Phase 11.2) can reuse without
// duplication.
//
// All functions are top-level so they can be imported with a
// simple `import '../utils/alert_ui_helper.dart';`.
// =============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Status colour
// ---------------------------------------------------------------------------

/// Returns the display colour for a given Firestore alert [status] string.
///
/// Known values: 'active', 'accepted', 'resolved'.
Color alertStatusColor(String status) {
  switch (status) {
    case 'active':
      return const Color(0xFFFB923C); // orange
    case 'accepted':
      return const Color(0xFF3B82F6); // blue
    case 'resolved':
      return const Color(0xFF22C55E); // green
    default:
      return const Color(0xFF0EA5E9); // sky
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
