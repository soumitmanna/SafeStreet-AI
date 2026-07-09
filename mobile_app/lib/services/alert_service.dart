// =============================================================
// SafeStreet
// Alert Service
//
// Single service for all Firestore operations on the 'alerts'
// collection (reads and status updates).
//
// Alert CREATION is handled exclusively by SosService, which
// resolves real GPS coordinates and sends SMS notifications.
//
// Status values (lowercase, project-wide standard):
//   'active'   — alert is live and awaiting a volunteer
//   'accepted' — a volunteer has accepted and is responding
//   'resolved' — the SOS has ended
//
// Volunteer arrival fields (Phase 11.3):
//   arrived   (bool)      — true once the volunteer taps "Mark Arrived"
//   arrivedAt (Timestamp) — server timestamp of arrival
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Listens to a single alert document by id.
  Stream<DocumentSnapshot> getAlert(String alertId) {
    return _firestore.collection('alerts').doc(alertId).snapshots();
  }

  /// Returns all active SOS alerts ordered by newest first.
  ///
  /// Filters on status == 'active' (lowercase) to match the value
  /// written by SosService.createActiveAlert().
  Stream<QuerySnapshot> getActiveAlerts() {
    return _firestore
        .collection('alerts')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Accept an SOS alert as a volunteer/helper.
  Future<void> acceptAlert({
    required String alertId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    await _firestore.collection('alerts').doc(alertId).update({
      'status': 'accepted',
      'acceptedBy': user.uid,
      'acceptedEmail': user.email ?? '',
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Record that the responding volunteer has physically arrived at the
  /// victim's location.
  ///
  /// Sets [arrived] = true and [arrivedAt] = server timestamp.
  /// A bool is used instead of a status string because arrival is a
  /// binary, one-way event with no intermediate states.
  Future<void> markArrived(String alertId) async {
    await _firestore.collection('alerts').doc(alertId).update({
      'arrived': true,
      'arrivedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark an SOS alert as resolved.
  ///
  /// Called by AssistScreen when the user taps "End SOS", and by
  /// VolunteerAssistanceScreen when the volunteer taps "Resolve Assistance".
  Future<void> resolveAlert(String alertId) async {
    await _firestore.collection('alerts').doc(alertId).update({
      'status': 'resolved',
      'resolved': true,
    });
  }
}