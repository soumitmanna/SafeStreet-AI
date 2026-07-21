// =============================================================
// SafeStreet
// Unsafe Zone Service
//
// Single service for all Firestore operations on the
// 'unsafe_zones' collection.
//
// Responsibilities:
//   • Input validation (coordinates, description length)
//   • Auth-guarding all write operations
//   • CRUD methods and real-time stream methods
//
// This service does NOT:
//   • Perform any UI interaction
//   • Resolve GPS coordinates (use LocationService for that)
//   • Enforce admin-level access (deferred to Firestore rules)
//
// Stream return types use fully-typed generics (Refinement 1, Phase 12.4):
//   streamZones()  → Stream<QuerySnapshot<Map<String, dynamic>>>
//   streamZone(id) → Stream<DocumentSnapshot<Map<String, dynamic>>>
//
// Phase 12.2:
//   Methods: createZone, updateZone, deleteZone,
//            getZone, streamZones, streamZone.
//
//   verifyZone() is intentionally absent — no admin moderation
//   workflow exists in this phase.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/unsafe_zone_model.dart';

class UnsafeZoneService {
  UnsafeZoneService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // ── Collection reference ───────────────────────────────────────────────────

  /// Reference to the top-level 'unsafe_zones' collection.
  ///
  /// Defined once here so that any future rename or path change
  /// is made in a single location.
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('unsafe_zones');

  // ── Validation ─────────────────────────────────────────────────────────────

  /// Maximum number of characters allowed in a zone description.
  static const int _maxDescriptionLength = 500;

  /// Validates that [latitude] is within the legal WGS-84 range.
  ///
  /// Throws an [Exception] if the value is out of range.
  void _validateLatitude(double latitude) {
    if (latitude < -90.0 || latitude > 90.0) {
      throw Exception(
        'Invalid latitude: value must be between -90.0 and 90.0.',
      );
    }
  }

  /// Validates that [longitude] is within the legal WGS-84 range.
  ///
  /// Throws an [Exception] if the value is out of range.
  void _validateLongitude(double longitude) {
    if (longitude < -180.0 || longitude > 180.0) {
      throw Exception(
        'Invalid longitude: value must be between -180.0 and 180.0.',
      );
    }
  }

  /// Validates the trimmed [description] for non-empty content and
  /// maximum length.
  ///
  /// Throws an [Exception] for an empty or oversized description.
  void _validateDescription(String description) {
    final trimmed = description.trim();

    if (trimmed.isEmpty) {
      throw Exception('Description cannot be empty.');
    }

    if (trimmed.length > _maxDescriptionLength) {
      throw Exception(
        'Description is too long (max $_maxDescriptionLength characters).',
      );
    }
  }

  /// Returns the currently authenticated user.
  ///
  /// Throws an [Exception] if no user is signed in. This mirrors the
  /// auth guard pattern used throughout the app services.
  User _requireAuth() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    return user;
  }

  // ── Write methods ──────────────────────────────────────────────────────────

  /// Creates a new unsafe zone document in the 'unsafe_zones' collection.
  ///
  /// Validates [latitude], [longitude], and [description] before writing.
  /// The [reportedBy] field is set automatically from the authenticated
  /// user's UID. [verified] defaults to false. [createdAt] is set via
  /// [FieldValue.serverTimestamp()].
  ///
  /// Returns the auto-generated Firestore document ID of the new zone.
  ///
  /// Throws:
  ///   • [Exception] if the user is not authenticated.
  ///   • [Exception] if any input fails validation.
  ///   • [Exception] wrapping a [FirebaseException] if the Firestore
  ///     write fails.
  Future<String> createZone({
    required double latitude,
    required double longitude,
    required UnsafeZoneCategory category,
    required String description,
  }) async {
    final user = _requireAuth();

    _validateLatitude(latitude);
    _validateLongitude(longitude);
    _validateDescription(description);

    final zoneRef = _collection.doc();

    try {
      await zoneRef.set({
        'latitude': latitude,
        'longitude': longitude,
        'category': category.name,
        'description': description.trim(),
        'reportedBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'verified': false,
      });
    } on FirebaseException catch (error) {
      throw Exception(
        'Could not save zone. Please try again. (${error.code})',
      );
    } catch (error) {
      throw Exception(
        'Could not save zone. Please try again.',
      );
    }

    return zoneRef.id;
  }

  /// Updates mutable fields on an existing unsafe zone document.
  ///
  /// Only the fields explicitly provided are written to Firestore.
  /// The following fields are intentionally not updatable through
  /// this method: [reportedBy], [createdAt], [verified].
  ///
  /// Throws:
  ///   • [Exception] if the user is not authenticated.
  ///   • [Exception] if [description] is provided and fails validation.
  ///   • [Exception] wrapping a [FirebaseException] if the update fails.
  Future<void> updateZone({
    required String zoneId,
    String? description,
    UnsafeZoneCategory? category,
  }) async {
    _requireAuth();

    final updates = <String, dynamic>{};

    if (description != null) {
      _validateDescription(description);
      updates['description'] = description.trim();
    }

    if (category != null) {
      updates['category'] = category.name;
    }

    if (updates.isEmpty) {
      // Nothing to update — return early without touching Firestore.
      return;
    }

    try {
      await _collection.doc(zoneId).update(updates);
    } on FirebaseException catch (error) {
      throw Exception(
        'Could not update zone. Please try again. (${error.code})',
      );
    } catch (error) {
      throw Exception(
        'Could not update zone. Please try again.',
      );
    }
  }

  /// Permanently deletes an unsafe zone document.
  ///
  /// This is a hard delete. The consuming UI is responsible for
  /// confirming that the current user owns the zone before calling
  /// this method. Ownership enforcement at the Firestore level is
  /// handled by Security Rules (deferred to a later phase).
  ///
  /// Throws:
  ///   • [Exception] if the user is not authenticated.
  ///   • [Exception] wrapping a [FirebaseException] if the delete fails.
  Future<void> deleteZone(String zoneId) async {
    _requireAuth();

    try {
      await _collection.doc(zoneId).delete();
    } on FirebaseException catch (error) {
      throw Exception(
        'Could not delete zone. Please try again. (${error.code})',
      );
    } catch (error) {
      throw Exception(
        'Could not delete zone. Please try again.',
      );
    }
  }

  // ── Read methods ───────────────────────────────────────────────────────────

  /// Fetches a single unsafe zone document once by its [zoneId].
  ///
  /// Returns null if the document does not exist.
  ///
  /// Use [streamZone] when a live-updating snapshot is required.
  ///
  /// Throws:
  ///   • [Exception] wrapping a [FirebaseException] if the read fails.
  Future<UnsafeZoneModel?> getZone(String zoneId) async {
    try {
      final doc = await _collection.doc(zoneId).get();

      if (!doc.exists) {
        return null;
      }

      return UnsafeZoneModel.fromFirestore(doc);
    } on FirebaseException catch (error) {
      throw Exception(
        'Could not fetch zone. Please try again. (${error.code})',
      );
    } catch (error) {
      throw Exception(
        'Could not fetch zone. Please try again.',
      );
    }
  }

  // ── Stream methods ─────────────────────────────────────────────────────────

  /// Returns a real-time stream of all unsafe zone documents,
  /// ordered by [createdAt] descending (newest first).
  ///
  /// The return type uses the fully-typed generic
  /// [Stream<QuerySnapshot<Map<String, dynamic>>>] (Refinement 1).
  /// [_collection] is already typed as
  /// [CollectionReference<Map<String, dynamic>>], so [.snapshots()]
  /// already emits correctly-typed events; only the declared return
  /// type annotation was updated.
  ///
  /// The consuming screen iterates [QuerySnapshot.docs], each of which
  /// is a [QueryDocumentSnapshot<Map<String, dynamic>>], and passes
  /// each to [UnsafeZoneModel.fromFirestore].
  ///
  /// No filters are applied at this layer. Filtering by category,
  /// verified status, or proximity is a query concern deferred to
  /// later phases.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamZones() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Returns a real-time stream of a single unsafe zone document
  /// identified by [zoneId].
  ///
  /// The return type uses the fully-typed generic
  /// [Stream<DocumentSnapshot<Map<String, dynamic>>>] (Refinement 1).
  ///
  /// The stream emits a new snapshot whenever the document changes,
  /// enabling a future zone-detail screen to react to admin
  /// verification in real-time.
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamZone(String zoneId) {
    return _collection.doc(zoneId).snapshots();
  }
}
