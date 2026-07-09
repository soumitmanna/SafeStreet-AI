// =============================================================
// SafeStreet
// Alert Model
//
// Represents a single SOS alert document from the Firestore
// 'alerts' collection.
//
// This is a pure data model. All UI-specific concerns such as
// status colours, icons, and relative time formatting are
// handled by the consuming screen.
//
// Phase 11.3 additions:
//   • arrived   (bool)     — true once the volunteer taps
//                            "Mark Arrived" on VolunteerAssistanceScreen.
//   • arrivedAt (DateTime?) — server timestamp of arrival.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class AlertModel {
  /// Firestore document ID.
  final String id;

  /// UID of the user who raised this alert.
  final String userId;

  /// Email of the user who raised this alert.
  final String userEmail;

  /// Current status of the alert.
  /// Known values: 'active', 'accepted', 'resolved'.
  final String status;

  /// Server-side timestamp of when the alert was created.
  /// Nullable because Firestore server timestamps may arrive
  /// as null on the first local write before the server confirms.
  final DateTime? createdAt;

  /// Whether the alert has been resolved.
  final bool resolved;

  /// Human-readable location description.
  final String location;

  /// GPS latitude of the alert origin.
  final double latitude;

  /// GPS longitude of the alert origin.
  final double longitude;

  /// UID of the volunteer who accepted this alert.
  /// Null if not yet accepted.
  final String? acceptedBy;

  /// Email of the volunteer who accepted this alert.
  /// Null if not yet accepted.
  final String? acceptedEmail;

  /// Timestamp of when this alert was accepted.
  /// Null if not yet accepted.
  final DateTime? acceptedAt;

  /// Whether the responding volunteer has physically arrived at the victim's
  /// location. Set to true by AlertService.markArrived().
  final bool arrived;

  /// Server-side timestamp of when the volunteer marked themselves as arrived.
  /// Null until the volunteer taps "Mark Arrived".
  final DateTime? arrivedAt;

  const AlertModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.status,
    required this.createdAt,
    required this.resolved,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.acceptedBy,
    this.acceptedEmail,
    this.acceptedAt,
    this.arrived = false,
    this.arrivedAt,
  });

  /// Parses a Firestore [DocumentSnapshot] into an [AlertModel].
  ///
  /// Uses defensive casting with fallback defaults so that
  /// malformed or partially-written documents do not crash the UI.
  factory AlertModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final createdAtRaw = data['createdAt'];
    final acceptedAtRaw = data['acceptedAt'];
    final arrivedAtRaw = data['arrivedAt'];

    return AlertModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      status: data['status'] as String? ?? 'active',
      createdAt:
          createdAtRaw != null ? (createdAtRaw as Timestamp).toDate() : null,
      resolved: data['resolved'] as bool? ?? false,
      location: data['location'] as String? ?? 'Unknown location',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      acceptedBy: data['acceptedBy'] as String?,
      acceptedEmail: data['acceptedEmail'] as String?,
      acceptedAt:
          acceptedAtRaw != null ? (acceptedAtRaw as Timestamp).toDate() : null,
      arrived: data['arrived'] as bool? ?? false,
      arrivedAt:
          arrivedAtRaw != null ? (arrivedAtRaw as Timestamp).toDate() : null,
    );
  }

  @override
  String toString() {
    return 'AlertModel('
        'id: $id, '
        'userId: $userId, '
        'status: $status, '
        'location: $location, '
        'createdAt: $createdAt'
        ')';
  }
}
