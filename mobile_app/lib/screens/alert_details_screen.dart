// =============================================================
// SafeStreet
// Alert Details Screen  —  Phase 11.2
//
// Opens when the user taps an alert card in AlertsScreen.
//
// Architecture:
//   • AlertModel is passed in as a constructor argument (zero
//     extra Firestore reads on navigation).
//   • StreamBuilder<DocumentSnapshot> wraps the entire body,
//     subscribing to AlertService.getAlert(alertId) for
//     real-time status updates.
//   • All UI helpers (statusColor, statusIcon, relativeTime,
//     formattedTimestamp, formattedCoords) come from
//     lib/utils/alert_ui_helper.dart — no duplication.
//   • Accept Alert calls AlertService.acceptAlert() — no
//     Firestore logic is duplicated.
//   • Open in Google Maps uses url_launcher exactly as in
//     rescue_screen.dart and sos_screen.dart.
//
// State managed here:
//   _isAccepting  — button loading guard (local only).
//   _hasAccepted  — session flag; prevents double-tap.
//                   The live stream shows the real status for
//                   all other viewers.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/alert_model.dart';
import '../services/alert_service.dart';
import '../utils/alert_ui_helper.dart';
import 'volunteer_assistance_screen.dart';

class AlertDetailsScreen extends StatefulWidget {
  const AlertDetailsScreen({super.key, required this.alert});

  /// The initial alert data, passed from AlertsScreen.
  /// Used to paint the screen instantly without an extra Firestore read.
  final AlertModel alert;

  @override
  State<AlertDetailsScreen> createState() => _AlertDetailsScreenState();
}

class _AlertDetailsScreenState extends State<AlertDetailsScreen> {
  /// Instantiated once for the lifetime of this State object.
  final AlertService _alertService = AlertService();

  /// True while the acceptAlert() call is in-flight.
  bool _isAccepting = false;

  /// True once the current user has successfully accepted this alert
  /// in this session. Prevents double-tap.
  bool _hasAccepted = false;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _acceptAlert(String alertId) async {
    if (_isAccepting || _hasAccepted) return;

    setState(() => _isAccepting = true);

    try {
      await _alertService.acceptAlert(alertId: alertId);
      if (!mounted) return;
      setState(() {
        _isAccepting = false;
        _hasAccepted = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isAccepting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Could not accept alert: $error'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFDC2626),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
    }
  }

  Future<void> _openInMaps(double latitude, double longitude) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Could not open Google Maps.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFDC2626),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _alertService.getAlert(widget.alert.id),
      builder: (context, snapshot) {
        // Use live Firestore model if available;
        // fall back to the passed-in model while the stream connects.
        final AlertModel alert =
            snapshot.hasData && snapshot.data!.exists
                ? AlertModel.fromFirestore(snapshot.data!)
                : widget.alert;

        // ── Firestore error ───────────────────────────────────────────────
        if (snapshot.hasError) {
          return _buildScaffold(
            alert: alert,
            body: _buildErrorState(),
          );
        }

        return _buildScaffold(
          alert: alert,
          body: _buildBody(context, alert),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Scaffold shell
  // ---------------------------------------------------------------------------

  Widget _buildScaffold({
    required AlertModel alert,
    required Widget body,
  }) {
    final color = alertStatusColor(alert.status);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Alert Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        // Coloured status dot in the trailing so context is always visible
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(child: body),
    );
  }

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              "Couldn't load real-time updates. "
              "The data shown may be out of date.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main body
  // ---------------------------------------------------------------------------

  Widget _buildBody(BuildContext context, AlertModel alert) {
    final theme = Theme.of(context);
    final color = alertStatusColor(alert.status);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    // The alert is no longer active if it has been accepted or resolved.
    final bool isStillActive = alert.status == 'active';

    // The current user was the one who accepted it.
    final bool acceptedByMe =
        _hasAccepted ||
        (alert.acceptedBy != null &&
            currentUid != null &&
            alert.acceptedBy == currentUid);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero card ──────────────────────────────────────────────────
          _buildHeroCard(theme, alert, color),
          const SizedBox(height: 20),

          // ── Details grid ───────────────────────────────────────────────
          _buildDetailsCard(theme, alert),
          const SizedBox(height: 20),

          // ── Resolution status card ─────────────────────────────────────
          _buildResolutionCard(theme, alert, color),
          const SizedBox(height: 24),

          // ── Action buttons ─────────────────────────────────────────────
          _buildMapButton(alert),
          const SizedBox(height: 12),
          _buildAcceptButton(
            theme: theme,
            alert: alert,
            isStillActive: isStillActive,
            acceptedByMe: acceptedByMe,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Hero card
  // ---------------------------------------------------------------------------

  Widget _buildHeroCard(ThemeData theme, AlertModel alert, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon circle
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              alertStatusIcon(alert.status),
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          // Location + time + badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.location,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  alertRelativeTime(alert.createdAt),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.28)),
                  ),
                  child: Text(
                    alert.status.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Details card
  // ---------------------------------------------------------------------------

  Widget _buildDetailsCard(ThemeData theme, AlertModel alert) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alert Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            icon: Icons.person_outline_rounded,
            label: 'Victim',
            value: alert.userEmail.isNotEmpty ? alert.userEmail : 'Anonymous',
          ),
          _buildDivider(),
          _buildDetailRow(
            icon: Icons.access_time_rounded,
            label: 'Reported',
            value: alertFormattedTimestamp(alert.createdAt),
          ),
          _buildDivider(),
          _buildDetailRow(
            icon: Icons.my_location_rounded,
            label: 'GPS',
            value: alertFormattedCoords(alert.latitude, alert.longitude),
            monospace: true,
          ),
          _buildDivider(),
          _buildDetailRow(
            icon: Icons.location_on_rounded,
            label: 'Location',
            value: alert.location,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool monospace = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: Colors.black54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: monospace
                      ? theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        )
                      : theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, color: Colors.black12);

  // ---------------------------------------------------------------------------
  // Resolution status card
  // ---------------------------------------------------------------------------

  Widget _buildResolutionCard(
    ThemeData theme,
    AlertModel alert,
    Color color,
  ) {
    final String title;
    final String subtitle;
    final IconData cardIcon;

    switch (alert.status) {
      case 'resolved':
        title = 'Alert Resolved';
        subtitle = 'This emergency has been resolved successfully.';
        cardIcon = Icons.check_circle_rounded;
      case 'accepted':
        final by = alert.acceptedEmail ?? alert.acceptedBy ?? 'a responder';
        final at = alertFormattedTimestamp(alert.acceptedAt);
        title = 'Accepted by $by';
        subtitle = 'Response started · $at';
        cardIcon = Icons.shield_rounded;
      default: // active
        title = 'Awaiting Response';
        subtitle = 'No responder has accepted this alert yet.';
        cardIcon = Icons.hourglass_top_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(cardIcon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action buttons
  // ---------------------------------------------------------------------------

  Widget _buildMapButton(AlertModel alert) {
    return OutlinedButton.icon(
      onPressed: () => _openInMaps(alert.latitude, alert.longitude),
      icon: const Icon(Icons.map_rounded),
      label: const Text('Open in Google Maps'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2563EB),
        side: const BorderSide(color: Color(0xFF2563EB)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAcceptButton({
    required ThemeData theme,
    required AlertModel alert,
    required bool isStillActive,
    required bool acceptedByMe,
  }) {
    // ── State 1: current user already accepted in this session ────────────
    if (acceptedByMe) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Confirmation label
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'You accepted this alert',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF16A34A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Navigation button to VolunteerAssistanceScreen
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VolunteerAssistanceScreen(alert: alert),
                ),
              );
            },
            icon: const Icon(Icons.volunteer_activism_rounded),
            label: const Text('Continue to Assistance'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    }

    // ── State 2: alert accepted/resolved by someone else ─────────────────
    if (!isStillActive) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              alertStatusIcon(alert.status),
              color: alertStatusColor(alert.status),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              alert.status == 'resolved'
                  ? 'Alert resolved'
                  : 'Already accepted by another responder',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // ── State 3: active — user can accept ─────────────────────────────────
    return ElevatedButton.icon(
      onPressed: _isAccepting ? null : () => _acceptAlert(alert.id),
      icon: _isAccepting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.volunteer_activism_rounded),
      label: Text(_isAccepting ? 'Accepting...' : 'Accept Alert'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF16A34A),
        disabledBackgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.6),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
