// =============================================================
// SafeStreet
// Volunteer Assistance Screen  —  Phase 11.3
//
// Opens after a volunteer accepts an alert in AlertDetailsScreen.
//
// Architecture:
//   • AlertModel is passed in as a constructor argument (zero
//     extra Firestore reads on navigation).
//   • StreamBuilder<DocumentSnapshot> wraps the entire body,
//     subscribing to AlertService.getAlert(alertId) for
//     real-time status updates — same pattern as AlertDetailsScreen.
//   • Distance is computed via Geolocator.distanceBetween() using
//     the existing geolocator package. No new packages introduced.
//   • Location is fetched via the existing LocationService.
//   • All Firestore writes route through AlertService — no direct
//     Firestore access from this widget.
//   • All UI helpers come from lib/utils/alert_ui_helper.dart.
//
// Local state managed here:
//   _distanceMeters     — computed straight-line distance (nullable).
//   _isLoadingLocation  — true while the initial location fetch runs.
//   _isMarkingArrived   — button loading guard.
//   _hasMarkedArrived   — session flag; prevents double-tap.
//   _isResolving        — button loading guard.
//
// Refinements (user-approved):
//   • arrived (bool) + arrivedAt (Timestamp) — no volunteerStatus string.
//   • Confirmation dialog before resolving.
//   • "Refresh Distance" button for manual distance refresh.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/alert_model.dart';
import '../services/alert_service.dart';
import '../services/location_service.dart';
import '../utils/alert_ui_helper.dart';

class VolunteerAssistanceScreen extends StatefulWidget {
  const VolunteerAssistanceScreen({super.key, required this.alert});

  /// Initial alert data passed from AlertDetailsScreen.
  /// Used for instant first paint — no extra Firestore read.
  final AlertModel alert;

  @override
  State<VolunteerAssistanceScreen> createState() =>
      _VolunteerAssistanceScreenState();
}

class _VolunteerAssistanceScreenState
    extends State<VolunteerAssistanceScreen> {
  final AlertService _alertService = AlertService();
  final LocationService _locationService = LocationService();

  /// Straight-line distance to the victim in metres. Null when unavailable.
  double? _distanceMeters;

  /// True while the initial or refreshed location fetch is in-flight.
  bool _isLoadingLocation = false;

  /// True while the markArrived() call is in-flight.
  bool _isMarkingArrived = false;

  /// True once markArrived() has succeeded in this session.
  bool _hasMarkedArrived = false;

  /// True while the resolveAlert() call is in-flight.
  bool _isResolving = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _fetchVolunteerLocation();
  }

  // ---------------------------------------------------------------------------
  // Location & Distance
  // ---------------------------------------------------------------------------

  /// Fetches the volunteer's current GPS position and computes the
  /// straight-line distance to the victim.
  ///
  /// Failure is non-fatal — the screen remains fully functional without
  /// a distance reading (navigation and action buttons are unaffected).
  Future<void> _fetchVolunteerLocation() async {
    if (_isLoadingLocation) return;
    setState(() => _isLoadingLocation = true);

    try {
      final position = await _locationService.getCurrentLocation();
      if (!mounted) return;

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        widget.alert.latitude,
        widget.alert.longitude,
      );

      setState(() {
        _distanceMeters = distance;
        _isLoadingLocation = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _distanceMeters = null;
        _isLoadingLocation = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _openNavigation(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=walking',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      _showSnackBar(
        'Could not open Google Maps.',
        backgroundColor: const Color(0xFFDC2626),
      );
    }
  }

  Future<void> _markArrived(String alertId) async {
    if (_isMarkingArrived || _hasMarkedArrived) return;
    setState(() => _isMarkingArrived = true);

    try {
      await _alertService.markArrived(alertId);
      if (!mounted) return;
      setState(() {
        _isMarkingArrived = false;
        _hasMarkedArrived = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isMarkingArrived = false);
      _showSnackBar(
        'Could not mark arrival: $error',
        backgroundColor: const Color(0xFFDC2626),
      );
    }
  }

  Future<void> _resolveAssistance(String alertId) async {
    // ── Confirmation dialog ───────────────────────────────────────────────
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Resolve Assistance',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'This will mark the incident as resolved and close the alert for all parties. Are you sure?',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isResolving = true);

    try {
      await _alertService.resolveAlert(alertId);
      if (!mounted) return;
      // Pop back to AlertDetailsScreen — its live stream will update to 'resolved'.
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isResolving = false);
      _showSnackBar(
        'Could not resolve alert: $error',
        backgroundColor: const Color(0xFFDC2626),
      );
    }
  }

  void _showSnackBar(String message, {required Color backgroundColor}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _alertService.getAlert(widget.alert.id),
      builder: (context, snapshot) {
        // Use live model when available; fall back to the constructor arg.
        final AlertModel alert =
            snapshot.hasData && snapshot.data!.exists
                ? AlertModel.fromFirestore(snapshot.data!)
                : widget.alert;

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

  Widget _buildScaffold({required AlertModel alert, required Widget body}) {
    final color = alertStatusColor(alert.status);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Volunteer Assistance'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
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
    final isResolved = alert.status == 'resolved';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero status card ───────────────────────────────────────────
          _buildHeroCard(theme, alert, color),
          const SizedBox(height: 20),

          // ── Alert info card ────────────────────────────────────────────
          _buildAlertInfoCard(theme, alert),
          const SizedBox(height: 20),

          // ── Volunteer status card ──────────────────────────────────────
          _buildVolunteerStatusCard(theme, alert, color),
          const SizedBox(height: 20),

          // ── Distance card ──────────────────────────────────────────────
          _buildDistanceCard(theme, alert),
          const SizedBox(height: 24),

          // ── Action buttons (hidden when resolved) ──────────────────────
          if (!isResolved) ...[
            _buildNavigationButton(alert),
            const SizedBox(height: 12),
            _buildMarkArrivedButton(theme, alert),
            const SizedBox(height: 12),
            _buildResolveButton(alert),
          ] else
            _buildResolvedBanner(theme),
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
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(alertStatusIcon(alert.status), color: color, size: 32),
          ),
          const SizedBox(width: 16),
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
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 10),
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
  // Alert info card
  // ---------------------------------------------------------------------------

  Widget _buildAlertInfoCard(ThemeData theme, AlertModel alert) {
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
          _buildInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Victim',
            value: alert.userEmail.isNotEmpty ? alert.userEmail : 'Anonymous',
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.access_time_rounded,
            label: 'Reported',
            value: alertFormattedTimestamp(alert.createdAt),
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.my_location_rounded,
            label: 'GPS',
            value: alertFormattedCoords(alert.latitude, alert.longitude),
            monospace: true,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.location_on_rounded,
            label: 'Location',
            value: alert.location,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
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
  // Volunteer status card
  // ---------------------------------------------------------------------------

  Widget _buildVolunteerStatusCard(
    ThemeData theme,
    AlertModel alert,
    Color color,
  ) {
    // Derive the volunteer status purely from the bool fields —
    // no volunteerStatus string needed.
    final bool hasArrived = _hasMarkedArrived || alert.arrived;
    final isResolved = alert.status == 'resolved';

    final String title;
    final String subtitle;
    final IconData cardIcon;
    final Color cardColor;

    if (isResolved) {
      title = 'Incident Resolved';
      subtitle = 'The alert has been successfully closed.';
      cardIcon = Icons.check_circle_rounded;
      cardColor = const Color(0xFF22C55E);
    } else if (hasArrived) {
      title = 'Arrived at Location';
      subtitle = alertFormattedTimestamp(alert.arrivedAt);
      cardIcon = Icons.location_on_rounded;
      cardColor = const Color(0xFF3B82F6);
    } else {
      title = 'En Route';
      subtitle = 'Heading to the victim\'s location.';
      cardIcon = Icons.directions_run_rounded;
      cardColor = const Color(0xFFFB923C);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardColor.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(cardIcon, color: cardColor, size: 22),
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
  // Distance card
  // ---------------------------------------------------------------------------

  Widget _buildDistanceCard(ThemeData theme, AlertModel alert) {
    final String distanceLabel;
    if (_isLoadingLocation) {
      distanceLabel = 'Calculating…';
    } else if (_distanceMeters == null) {
      distanceLabel = 'Distance unavailable';
    } else if (_distanceMeters! < 1000) {
      distanceLabel =
          '~${_distanceMeters!.toStringAsFixed(0)} m straight-line';
    } else {
      distanceLabel =
          '~${(_distanceMeters! / 1000).toStringAsFixed(2)} km straight-line';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.straighten_rounded,
              color: Color(0xFF2563EB),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distance to victim',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                _isLoadingLocation
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        distanceLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
              ],
            ),
          ),
          // Refresh Distance button
          TextButton.icon(
            onPressed: _isLoadingLocation ? null : _fetchVolunteerLocation,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Refresh'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action buttons
  // ---------------------------------------------------------------------------

  Widget _buildNavigationButton(AlertModel alert) {
    return OutlinedButton.icon(
      onPressed: () => _openNavigation(alert.latitude, alert.longitude),
      icon: const Icon(Icons.navigation_rounded),
      label: const Text('Open Navigation'),
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

  Widget _buildMarkArrivedButton(ThemeData theme, AlertModel alert) {
    final bool hasArrived = _hasMarkedArrived || alert.arrived;

    // Already arrived — show a static confirmation badge instead of a button
    if (hasArrived) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on_rounded,
              color: Color(0xFF2563EB),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Arrived at location',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF1D4ED8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed:
          _isMarkingArrived ? null : () => _markArrived(alert.id),
      icon: _isMarkingArrived
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.location_on_rounded),
      label: Text(_isMarkingArrived ? 'Marking…' : 'Mark Arrived'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        disabledBackgroundColor:
            const Color(0xFF2563EB).withValues(alpha: 0.6),
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

  Widget _buildResolveButton(AlertModel alert) {
    return ElevatedButton.icon(
      onPressed: _isResolving ? null : () => _resolveAssistance(alert.id),
      icon: _isResolving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.check_circle_rounded),
      label: Text(_isResolving ? 'Resolving…' : 'Resolve Assistance'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF16A34A),
        disabledBackgroundColor:
            const Color(0xFF16A34A).withValues(alpha: 0.6),
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

  // ---------------------------------------------------------------------------
  // Resolved banner (replaces all buttons when alert is already resolved)
  // ---------------------------------------------------------------------------

  Widget _buildResolvedBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF16A34A),
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alert Resolved',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF14532D),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This incident has been successfully closed.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF166534),
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
}
