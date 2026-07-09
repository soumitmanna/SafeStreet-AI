// =============================================================
// SafeStreet
// Alerts Screen  —  Phase 11.2
//
// Changes from Phase 11.1:
//   • Status colour, status icon, and relative time helpers
//     extracted to lib/utils/alert_ui_helper.dart so that
//     AlertDetailsScreen can reuse the same logic.
//   • Card onTap wired to AlertDetailsScreen (was a no-op
//     placeholder in Phase 11.1).
//   • AlertModel is passed directly to AlertDetailsScreen;
//     no extra Firestore read on navigation.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/alert_model.dart';
import '../services/alert_service.dart';
import '../utils/alert_ui_helper.dart';
import 'alert_details_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  /// Instantiated once for the lifetime of this State object.
  final AlertService _alertService = AlertService();

  // ---------------------------------------------------------------------------
  // UI helpers are in lib/utils/alert_ui_helper.dart
  // (alertStatusColor, alertStatusIcon, alertRelativeTime)
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Alerts'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _alertService.getActiveAlerts(),
          builder: (context, snapshot) {
            // ── Loading ──────────────────────────────────────────────────────
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // ── Error ────────────────────────────────────────────────────────
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 52,
                        color: Colors.black26,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Couldn't load alerts. Check your internet connection and try again.",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // ── Parse documents ──────────────────────────────────────────────
            final docs = snapshot.data?.docs ?? [];
            final alerts =
                docs.map(AlertModel.fromFirestore).toList();

            // ── Empty ────────────────────────────────────────────────────────
            if (alerts.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        size: 52,
                        color: Colors.black26,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "You're safe! No active alerts nearby.",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // ── Data ─────────────────────────────────────────────────────────
            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent incident alerts',
                          style:
                              theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'View the latest activity and status updates for your safety network.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black54, height: 1.4),
                        ),
                        const SizedBox(height: 22),
                        isWide
                            ? Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: alerts
                                    .map(
                                      (alert) => SizedBox(
                                        width:
                                            (constraints.maxWidth - 60) /
                                                2,
                                        child: _buildAlertCard(
                                            context, alert),
                                      ),
                                    )
                                    .toList(),
                              )
                            : Column(
                                children: alerts
                                    .map(
                                      (alert) => Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 16),
                                        child: _buildAlertCard(
                                            context, alert),
                                      ),
                                    )
                                    .toList(),
                              ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card builder
  // ---------------------------------------------------------------------------

  Widget _buildAlertCard(BuildContext context, AlertModel alert) {
    final theme = Theme.of(context);
    final color = alertStatusColor(alert.status);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AlertDetailsScreen(alert: alert),
          ),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Status icon
                Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  width: 52,
                  height: 52,
                  child: Icon(
                    alertStatusIcon(alert.status),
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                // Title + relative time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.location,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alertRelativeTime(alert.createdAt),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Text(
                    alert.status,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Reported-by row
            Row(
              children: [
                Icon(Icons.person_outline_rounded,
                    size: 14, color: Colors.black38),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    alert.userEmail.isNotEmpty
                        ? alert.userEmail
                        : 'Anonymous',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.black54),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
