// =============================================================
// SafeStreet
// Report Unsafe Zone Sheet  —  Phase 12.3
//
// Modal bottom sheet for submitting a new community unsafe zone
// report. Opened by UnsafeZoneMapScreen when the user long-presses
// a location on the Community Map.
//
// Architecture:
//   • location (LatLng) is injected by the parent — no async
//     GPS fetch is required inside this widget.
//   • UnsafeZoneService is injected by the parent — no direct
//     Firestore logic exists inside this widget.
//   • onSuccess callback is invoked before Navigator.pop so the
//     parent can show a SnackBar while its context is still valid.
//   • All post-await context accesses are guarded by mounted checks.
//
// UI:
//   • "Selected location on map" label (no raw coordinates shown).
//   • Category selection via ChoiceChip (driven by UnsafeZoneCategory.values).
//   • Description TextField (max 500 characters).
//   • Confirmation AlertDialog before submission.
//   • Inline error text for pre-flight and service failures.
//
// Future Scalability:
//   Future versions may detect and prevent or merge duplicate reports
//   submitted at nearly the same coordinates within a short time window
//   to reduce noise in the unsafe_zones collection. This is not
//   implemented in Phase 12.3.
// =============================================================

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/unsafe_zone_model.dart';
import '../services/unsafe_zone_service.dart';
import '../theme/app_theme.dart';
import '../utils/zone_ui_helper.dart';

class ReportUnsafeZoneSheet extends StatefulWidget {
  const ReportUnsafeZoneSheet({
    super.key,
    required this.location,
    required this.service,
    required this.onSuccess,
  });

  /// The map coordinate selected by the user via long press.
  ///
  /// Stored internally and passed to [UnsafeZoneService.createZone].
  /// Displayed to the user only as a friendly label — raw coordinates
  /// are never shown in the UI.
  final LatLng location;

  /// Service instance provided by [UnsafeZoneMapScreen].
  ///
  /// Never instantiated inside this widget.
  final UnsafeZoneService service;

  /// Called after a successful Firestore write, before [Navigator.pop].
  ///
  /// The parent uses this to show a success SnackBar while its
  /// [BuildContext] is still mounted and valid.
  final VoidCallback onSuccess;

  @override
  State<ReportUnsafeZoneSheet> createState() => _ReportUnsafeZoneSheetState();
}

class _ReportUnsafeZoneSheetState extends State<ReportUnsafeZoneSheet> {
  // ── Form state ─────────────────────────────────────────────────────────────

  /// The category chosen by the user via ChoiceChip.
  /// Null while no selection has been made.
  UnsafeZoneCategory? _selectedCategory;

  final TextEditingController _descriptionController = TextEditingController();

  // ── Submission state ───────────────────────────────────────────────────────

  /// True while [UnsafeZoneService.createZone] is in-flight.
  /// Prevents double-submission and disables all form controls.
  bool _isSubmitting = false;

  /// Non-null when a pre-flight or service error has occurred.
  /// Displayed as inline red text below the description field.
  String? _errorMessage;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  //
  // _categoryLabel has been removed in Phase 12.4.
  // zoneCategoryLabel(category) from zone_ui_helper.dart is used instead,
  // keeping the label logic in a single shared location.

  // ── Submission ─────────────────────────────────────────────────────────────

  Future<void> _submitReport() async {
    // ── Pre-flight validation ────────────────────────────────────────────────
    //
    // These checks run before touching the service so the user gets
    // immediate feedback without a network round-trip.

    if (_selectedCategory == null) {
      setState(() => _errorMessage = 'Please select a category.');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please describe the hazard.');
      return;
    }

    setState(() => _errorMessage = null);

    // ── Confirmation dialog ──────────────────────────────────────────────────
    //
    // Prevents accidental submissions from an errant long press.

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Submit Report'),
        content: const Text('Submit this unsafe zone report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    // Guard after async dialog.
    if (!mounted) return;

    // User tapped Cancel inside the confirmation dialog.
    if (confirmed != true) return;

    // ── Service call ─────────────────────────────────────────────────────────

    setState(() => _isSubmitting = true);

    try {
      await widget.service.createZone(
        latitude: widget.location.latitude,
        longitude: widget.location.longitude,
        category: _selectedCategory!,
        description: _descriptionController.text.trim(),
      );

      // Guard after async service call.
      if (!mounted) return;

      // Notify the parent before popping so it can show a SnackBar
      // while its own context is still valid.
      widget.onSuccess();

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        // Strip the leading "Exception: " prefix that Dart adds so the
        // message reads cleanly in the UI.
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // ── Drag handle ────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Title ──────────────────────────────────────────────────────────
          const Text(
            'Report Unsafe Zone',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
          ),

          const SizedBox(height: 8),

          // ── Location label ─────────────────────────────────────────────────
          //
          // Shows a friendly label, not raw coordinates.
          // The actual LatLng is stored in widget.location and passed
          // to the service — never exposed in the UI.
          const Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 16,
                color: AppTheme.primaryBlue,
              ),
              SizedBox(width: 6),
              Text(
                'Selected location on map',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Category section ───────────────────────────────────────────────
          const Text(
            'Category',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),

          const SizedBox(height: 10),

          // Chips are built from UnsafeZoneCategory.values so that any
          // future enum additions appear automatically — no hardcoded strings.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: UnsafeZoneCategory.values.map((category) {
              final isSelected = _selectedCategory == category;
              return ChoiceChip(
                label: Text(zoneCategoryLabel(category)),
                selected: isSelected,
                showCheckmark: false,
                onSelected: _isSubmitting
                    ? null
                    : (_) => setState(() {
                          _selectedCategory = category;
                          _errorMessage = null;
                        }),
                selectedColor: AppTheme.primaryBlue,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.darkText,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color:
                        isSelected ? AppTheme.primaryBlue : Colors.black12,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // ── Description section ────────────────────────────────────────────
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: _descriptionController,
            maxLines: 4,
            maxLength: 500,
            enabled: !_isSubmitting,
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              if (_errorMessage != null) {
                setState(() => _errorMessage = null);
              }
            },
            decoration: InputDecoration(
              hintText: 'Describe the hazard...',
              hintStyle: const TextStyle(color: Colors.black38),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.black12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppTheme.primaryBlue,
                  width: 1.5,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.black12),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),

          // ── Inline error message ───────────────────────────────────────────
          if (_errorMessage != null) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: AppTheme.emergencyRed,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.emergencyRed,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // ── Submit button ──────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Submit Report',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Cancel button ──────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed:
                  _isSubmitting ? null : () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}
