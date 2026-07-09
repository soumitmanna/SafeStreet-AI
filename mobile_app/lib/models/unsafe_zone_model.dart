// =============================================================
// SafeStreet
// Unsafe Zone Model
//
// Represents a single community-reported unsafe zone document
// from the Firestore 'unsafe_zones' collection.
//
// This is a pure data model. All UI-specific concerns such as
// marker colours, icons, and display formatting are handled
// by the consuming screen in later phases.
//
// Phase 12.2:
//   Initial model — id, latitude, longitude, category,
//   description, reportedBy, createdAt, verified.
//
// Phase 12.4:
//   fromFirestore updated to accept a typed
//   DocumentSnapshot<Map<String, dynamic>> (Refinement 1).
//   The unsafe `as Map<String, dynamic>` cast has been removed;
//   .data() on the typed snapshot returns Map<String, dynamic>?
//   directly so only a null-safety fallback (?? {}) is needed.
//
// Fields deliberately excluded in this phase:
//   • severity   — must not be reporter-supplied; deferred to
//                  a future moderation or ML phase.
//   • imageUrl   — Firebase Storage not in scope; evidence is
//                  handled separately by EvidenceModel.
//   • userEmail  — UID is sufficient at the service layer;
//                  email is a UI display concern.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

// ---------------------------------------------------------------------------
// Category enum
// ---------------------------------------------------------------------------

/// Classifies the type of danger reported for an unsafe zone.
///
/// Stored in Firestore as the lowercase string returned by [name]
/// (e.g. [harassment] → 'harassment').
///
/// When parsing, any unrecognised string falls back to [other]
/// so that future category additions in Firestore do not crash
/// older client versions.
enum UnsafeZoneCategory {
  harassment,
  theft,
  poorLighting,
  unsafePath,
  other,
}

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class UnsafeZoneModel {
  /// Firestore document ID.
  ///
  /// Populated from [DocumentSnapshot.id] — never stored inside
  /// the document body.
  final String id;

  /// GPS latitude of the reported zone.
  ///
  /// Valid range: -90.0 to 90.0.
  /// Validated by [UnsafeZoneService] before any Firestore write.
  final double latitude;

  /// GPS longitude of the reported zone.
  ///
  /// Valid range: -180.0 to 180.0.
  /// Validated by [UnsafeZoneService] before any Firestore write.
  final double longitude;

  /// Classification of the type of danger at this location.
  ///
  /// Stored in Firestore as [UnsafeZoneCategory.name].
  /// Parsed defensively with a fallback to [UnsafeZoneCategory.other].
  final UnsafeZoneCategory category;

  /// Free-text description provided by the reporter.
  ///
  /// Maximum 500 characters, enforced by [UnsafeZoneService.createZone]
  /// and [UnsafeZoneService.updateZone]. Cannot be empty.
  final String description;

  /// UID of the authenticated user who submitted this zone report.
  ///
  /// Set automatically by [UnsafeZoneService.createZone] from
  /// [FirebaseAuth.currentUser.uid]. Not editable after creation.
  final String reportedBy;

  /// Server-side timestamp of when the zone was first reported.
  ///
  /// Nullable because Firestore server timestamps may arrive as null
  /// on the first local write before the server confirms the value.
  /// This matches the same pattern used in [AlertModel.createdAt].
  final DateTime? createdAt;

  /// Whether this zone has been verified by an administrator.
  ///
  /// Defaults to false on creation. Set to true only through a
  /// future moderation workflow. There is no write path for this
  /// field in Phase 12.2.
  final bool verified;

  const UnsafeZoneModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.description,
    required this.reportedBy,
    required this.createdAt,
    required this.verified,
  });

  // ── Firestore factory ──────────────────────────────────────────────────────

  /// Parses a typed Firestore [DocumentSnapshot] into an [UnsafeZoneModel].
  ///
  /// The typed parameter eliminates the unsafe `as Map<String, dynamic>` cast:
  /// [DocumentSnapshot.data] on a typed snapshot already returns
  /// [Map<String, dynamic>?], so only a null-safety fallback is needed.
  ///
  /// Uses defensive field-level fallbacks so that malformed or
  /// partially-written documents do not crash the UI.
  ///
  /// The document ID is read from [doc.id], not from any stored field.
  factory UnsafeZoneModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final createdAtRaw = data['createdAt'];

    // Parse the category string back to the enum.
    // Falls back to [UnsafeZoneCategory.other] for any unknown value so
    // that adding new categories in Firestore is non-breaking for older builds.
    final categoryRaw = data['category'] as String? ?? 'other';
    final category = UnsafeZoneCategory.values.firstWhere(
      (e) => e.name == categoryRaw,
      orElse: () => UnsafeZoneCategory.other,
    );

    return UnsafeZoneModel(
      id: doc.id,
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      category: category,
      description: data['description'] as String? ?? '',
      reportedBy: data['reportedBy'] as String? ?? '',
      createdAt:
          createdAtRaw != null ? (createdAtRaw as Timestamp).toDate() : null,
      verified: data['verified'] as bool? ?? false,
    );
  }

  // ── Firestore serialisation ────────────────────────────────────────────────

  /// Converts this model to a [Map] suitable for writing to Firestore.
  ///
  /// The [id] field is intentionally excluded — it is the Firestore
  /// document ID and must not be stored as a document field.
  ///
  /// [createdAt] is also excluded here because it is always set via
  /// [FieldValue.serverTimestamp()] at the service layer, never from
  /// this model.
  Map<String, dynamic> toFirestore() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'category': category.name,
      'description': description,
      'reportedBy': reportedBy,
      'verified': verified,
    };
  }

  // ── Immutable update helper ────────────────────────────────────────────────

  /// Returns a copy of this model with the specified fields replaced.
  ///
  /// All other fields retain their current values.
  UnsafeZoneModel copyWith({
    String? id,
    double? latitude,
    double? longitude,
    UnsafeZoneCategory? category,
    String? description,
    String? reportedBy,
    DateTime? createdAt,
    bool? verified,
  }) {
    return UnsafeZoneModel(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      description: description ?? this.description,
      reportedBy: reportedBy ?? this.reportedBy,
      createdAt: createdAt ?? this.createdAt,
      verified: verified ?? this.verified,
    );
  }

  // ── Debug ──────────────────────────────────────────────────────────────────

  @override
  String toString() {
    return 'UnsafeZoneModel('
        'id: $id, '
        'category: ${category.name}, '
        'reportedBy: $reportedBy, '
        'verified: $verified, '
        'createdAt: $createdAt'
        ')';
  }
}
