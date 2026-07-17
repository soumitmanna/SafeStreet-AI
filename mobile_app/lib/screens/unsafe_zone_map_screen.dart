// =============================================================
// SafeStreet
// Unsafe Zone Map Screen  —  Phase 12.4
//
// Google Maps Foundation with live community unsafe zone markers.
//
// Phase 12.1 scope (unchanged):
//   • Full-screen GoogleMap widget.
//   • Camera automatically centers on the user's GPS position.
//   • "My Location" FAB re-centers on demand.
//   • Dismissible error banner for permission-denied and
//     GPS-disabled failure modes.
//   • LinearProgressIndicator while the location fix is in-flight.
//
// Phase 12.3 additions (unchanged):
//   • onLongPress handler on GoogleMap opens ReportUnsafeZoneSheet.
//   • Temporary red pin marker placed at the long-pressed coordinate
//     while the sheet is open.
//   • Hint overlay auto-dismisses after 4 s or on first long press.
//   • Success SnackBar after a successful zone submission.
//   • _isSheetOpen guard prevents overlapping sheets.
//
// Phase 12.4 additions:
//   • _startZonesStream() subscribes to UnsafeZoneService.streamZones().
//   • Each Firestore document is mapped to a colour-coded Marker via
//     UnsafeZoneModel.fromFirestore and zoneCategoryHue/zoneCategoryLabel
//     from zone_ui_helper.dart.
//   • _zoneMarkers holds community pins; _markers holds the temporary
//     pending-report pin. Both are merged as {..._zoneMarkers, ..._markers}.
//   • StreamSubscription is cancelled in dispose to prevent memory leaks.
//   • Marker interaction is InfoWindow only — no bottom sheet, no onTap.
//
// Out of scope (deferred to Phase 12.5+):
//   • Zone detail bottom sheet.
//   • Marker clustering or filtering.
//   • Heatmap overlay.
//   • Category filter controls.
//
// Architecture:
//   • UnsafeZoneService is instantiated once as a final field,
//     then injected into ReportUnsafeZoneSheet — no Firestore
//     logic lives in this widget.
//   • LocationService is reused for GPS + permission handling.
//     No duplicate permission logic here.
//   • GoogleMapController pattern mirrors rescue_screen.dart.
//   • State is plain setState — no external state management.
// =============================================================

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/unsafe_zone_model.dart';
import '../services/location_service.dart';
import '../services/unsafe_zone_service.dart';
import '../theme/app_theme.dart';
import '../utils/zone_ui_helper.dart';
import '../widgets/report_unsafe_zone_sheet.dart';
import '../models/prediction_exception.dart';
import '../models/prediction_request.dart';
import '../models/prediction_response.dart';
import '../services/prediction_service.dart';
import '../widgets/prediction_result_card.dart';

enum _PredictionStatus { idle, loading, success, error }

// ---------------------------------------------------------------------------
// Fallback camera position
// ---------------------------------------------------------------------------

/// Temporary default camera position used during development.
///
/// This is the map position shown when the user's real GPS location
/// cannot be obtained (permission denied, GPS disabled, or a timeout).
///
/// Replace with a production-appropriate default — for example the
/// geographic centre of the primary deployment region — before
/// releasing to production.
const CameraPosition _kDevelopmentFallbackPosition = CameraPosition(
  target: LatLng(22.5726, 88.3639), // Kolkata, West Bengal
  zoom: 15,
);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class UnsafeZoneMapScreen extends StatefulWidget {
  const UnsafeZoneMapScreen({super.key});

  @override
  State<UnsafeZoneMapScreen> createState() => _UnsafeZoneMapScreenState();
}

class _UnsafeZoneMapScreenState extends State<UnsafeZoneMapScreen> {
  // ── Services ───────────────────────────────────────────────────────────────

  /// Single service instance for all Firestore writes in this screen.
  /// Injected into [ReportUnsafeZoneSheet] — never used directly here.
  final UnsafeZoneService _unsafeZoneService = UnsafeZoneService();

  /// Shared location service for fetching position and starting streams.
  final LocationService _locationService = LocationService();

  // ── Prediction (Phase 10) ──────────────────────────────────────────────────
  late final PredictionService _predictionService;

  // ── Controllers ────────────────────────────────────────────────────────────

  /// Set once in onMapCreated; used to animate the camera.
  GoogleMapController? _mapController;

  // ── Map state ──────────────────────────────────────────────────────────────

  /// All community zones fetched from the latest Firestore snapshot.
  List<UnsafeZoneModel> _allZones = [];

  /// The currently selected filter categories. Empty means "All".
  Set<UnsafeZoneCategory> _selectedCategories = {};

  /// Community zone markers built from the latest Firestore snapshot.
  ///
  /// Populated and rebuilt on every [streamZones] emission by
  /// [_startZonesStream]. Merged with [_markers] in the [GoogleMap]
  /// `markers` prop as `{..._zoneMarkers, ..._markers}`.
  Set<Marker> _zoneMarkers = {};

  /// Temporary pending-report pin shown while [ReportUnsafeZoneSheet]
  /// is open.
  ///
  /// In Phase 12.3+ this contains at most one entry: the red pin placed
  /// at the long-pressed location. It is cleared when the sheet closes.
  Set<Marker> _markers = {};

  /// True while [ReportUnsafeZoneSheet] is showing.
  ///
  /// Prevents a second long press from opening a second sheet while
  /// the first one is still visible.
  bool _isSheetOpen = false;

  // ── Firestore stream ───────────────────────────────────────────────────────

  /// Live subscription to the unsafe_zones Firestore query stream.
  ///
  /// Typed as [StreamSubscription<QuerySnapshot<Map<String, dynamic>>>]
  /// in compliance with Refinement 1. Created once in [_startZonesStream]
  /// (called from [initState]) and cancelled in [dispose] to prevent
  /// listener leaks.
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _zonesSubscription;

  /// Phase 12.6: Location stream subscription for proximity detection.
  StreamSubscription<Position>? _positionSubscription;

  /// Cached latest position for cross-trigger checks (like a new zone
  /// appearing while the user is stationary).
  Position? _lastKnownPosition;

  /// IDs of zones the user has already been warned about on this visit.
  Set<String> _notifiedZoneIds = {};

  /// Threshold distance in metres for triggering an alert.
  static const double _kWarningRadiusMetres = 150.0;

  // ── Location state ─────────────────────────────────────────────────────────

  /// True while LocationService.getCurrentLocation() is in-flight.
  bool _isLoadingLocation = false;

  /// Non-null when a location failure has occurred.
  /// Drives the dismissible error banner.
  String? _locationError;

  // ── Hint state ─────────────────────────────────────────────────────────────

  /// True while the long-press hint overlay should be visible.
  ///
  /// Becomes false after 4 seconds or on the user's first long press,
  /// whichever comes first.
  bool _showHint = true;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _predictionService = PredictionService();
    _centerOnUserLocation();
    _scheduleHintDismissal();
    _startZonesStream();
  }

  @override
  void dispose() {
    _zonesSubscription?.cancel();
    _positionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Zones stream ───────────────────────────────────────────────────────────

  /// Subscribes to [UnsafeZoneService.streamZones] and rebuilds
  /// [_zoneMarkers] on every Firestore snapshot emission.
  ///
  /// Each [QueryDocumentSnapshot] is parsed via
  /// [UnsafeZoneModel.fromFirestore] (typed, no unsafe cast). A [Marker]
  /// is constructed for each zone with:
  ///   • [MarkerId] derived from [UnsafeZoneModel.id] (Firestore doc ID).
  ///   • Colour-coded hue from [zoneCategoryHue] via
  ///     [BitmapDescriptor.defaultMarkerWithHue].
  ///   • [InfoWindow] with [zoneCategoryLabel] as title and
  ///     [UnsafeZoneModel.description] as snippet.
  ///
  /// Stream errors are surfaced through [_locationError] so the
  /// existing dismissible error banner handles them — no duplicate
  /// error-display logic is needed.
  void _startZonesStream() {
    _zonesSubscription = _unsafeZoneService.streamZones().listen(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        if (!mounted) return;

        final parsedZones = <UnsafeZoneModel>[];

        for (final doc in snapshot.docs) {
          parsedZones.add(UnsafeZoneModel.fromFirestore(doc));
        }

        _allZones = parsedZones;
        _rebuildMarkers();
        _checkNearbyZones(_lastKnownPosition);
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _locationError =
              'Could not load community zones. Pull down to retry.';
        });
      },
    );
  }

  // ── Filtering and Marker Building ──────────────────────────────────────────

  void _onFilterChanged(Set<UnsafeZoneCategory> selected) {
    _selectedCategories = selected;
    _rebuildMarkers();
  }

  void _rebuildMarkers() {
    final newMarkers = <Marker>{};

    for (final zone in _allZones) {
      if (_selectedCategories.isNotEmpty &&
          !_selectedCategories.contains(zone.category)) {
        continue; // Skip if filtered out
      }

      newMarkers.add(
        Marker(
          markerId: MarkerId(zone.id),
          position: LatLng(zone.latitude, zone.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            zoneCategoryHue(zone.category),
          ),
          infoWindow: InfoWindow(
            title: zoneCategoryLabel(zone.category),
            snippet: _buildSnippet(zone),
          ),
        ),
      );
    }

    setState(() => _zoneMarkers = newMarkers);
  }

  String _buildSnippet(UnsafeZoneModel zone) {
    final dateStr = _formatDate(zone.createdAt);
    final verifiedStr = zone.verified ? '✓ Verified' : 'Unverified';

    return '${zone.description}\n\nReported: $dateStr  •  $verifiedStr';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Date unavailable';

    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = monthNames[dt.month - 1];

    return '${dt.day} $month ${dt.year}';
  }

  // ── Hint ───────────────────────────────────────────────────────────────────

  /// Schedules automatic dismissal of the long-press hint after 4 seconds.
  ///
  /// Uses [Future.delayed] rather than a [Timer] to avoid a separate
  /// cancel call in [dispose].
  void _scheduleHintDismissal() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _showHint) {
        setState(() => _showHint = false);
      }
    });
  }

  // ── Location ───────────────────────────────────────────────────────────────

  /// Fetches the user's current GPS position and animates the map camera
  /// to that location.
  ///
  /// On any failure the map remains rendered at [_kDevelopmentFallbackPosition]
  /// and [_locationError] is set, which shows the dismissible banner.
  ///
  /// Calling this method while a fetch is already in-flight is a no-op.
  Future<void> _centerOnUserLocation() async {
    if (_isLoadingLocation) return;

    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final position = await _locationService.getCurrentLocation();

      if (!mounted) return;

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16,
          ),
        ),
      );

      _startPositionStream();
    } on Exception catch (e) {
      if (!mounted) return;

      final message = e.toString();

      if (message.contains('Location services are disabled')) {
        _locationError =
            'GPS is disabled. Turn on location services to center the map.';
      } else if (message.contains('permanently denied')) {
        _locationError =
            'Location permission denied. Enable it in app settings.';
      } else {
        _locationError =
            'Could not get your location. The map is still available.';
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  // ── Phase 12.6 Nearby Detection ────────────────────────────────────────────

  void _startPositionStream() {
    _positionSubscription = _locationService.streamPosition().listen(
      (Position position) {
        if (!mounted) return;
        _lastKnownPosition = position;
        _checkNearbyZones(position);
      },
    );
  }

  void _checkNearbyZones(Position? position) {
    if (position == null) return;
    if (_allZones.isEmpty) return;

    // Remove exited zones from _notifiedZoneIds
    _notifiedZoneIds.removeWhere((notifiedZoneId) {
      final zone = _allZones.where((z) => z.id == notifiedZoneId).firstOrNull;
      if (zone == null) return true; // Zone deleted/filtered out

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        zone.latitude,
        zone.longitude,
      );
      return distance > _kWarningRadiusMetres;
    });

    // Find closest un-notified zone within radius
    UnsafeZoneModel? closestZone;
    double closestDistance = double.infinity;

    for (final zone in _allZones) {
      if (_notifiedZoneIds.contains(zone.id)) continue;

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        zone.latitude,
        zone.longitude,
      );

      if (distance <= _kWarningRadiusMetres && distance < closestDistance) {
        closestDistance = distance;
        closestZone = zone;
      }
    }

    if (closestZone != null) {
      _notifiedZoneIds.add(closestZone.id);
      _showNearbyWarning(closestZone, closestDistance);
    }
  }

  void _showNearbyWarning(UnsafeZoneModel zone, double distance) {
    if (!mounted) return;

    final banner = MaterialBanner(
      elevation: 4,
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: const Icon(
        Icons.warning_amber_rounded,
        color: AppTheme.emergencyRed,
        size: 32,
      ),
      content: Text(
        'Nearby unsafe area\n${zoneCategoryLabel(zone.category)}  •  ~${distance.round()} m away',
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            }
          },
          child: const Text('Dismiss'),
        ),
      ],
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(banner);

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      }
    });
  }

  // ── Reporting ──────────────────────────────────────────────────────────────

  /// Handles a long press on the map at [position].
  ///
  /// Places a temporary red pin at the pressed location, dismisses the
  /// hint overlay on first use, and opens [ReportUnsafeZoneSheet].
  void _onLongPress(LatLng position) {
    // Prevent a second sheet while one is already open.
    if (_isSheetOpen) return;

    // Dismiss the hint on first interaction.
    if (_showHint) {
      setState(() => _showHint = false);
    }

    // Place a temporary marker at the reported location so the user
    // can see exactly which point they are submitting.
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('pending_report'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Report location'),
        ),
      };
    });

    _showReportSheet(position);
  }

  /// Opens [ReportUnsafeZoneSheet] for the given [location].
  ///
  /// Sets [_isSheetOpen] to true for the duration of the sheet.
  /// Clears the temporary pin marker and resets the guard flag when
  /// the sheet closes, regardless of how it was dismissed.
  Future<void> _showReportSheet(LatLng location) async {
    setState(() => _isSheetOpen = true);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ReportUnsafeZoneSheet(
        location: location,
        service: _unsafeZoneService,
        onSuccess: _onReportSuccess,
      ),
    );

    // Runs after the sheet closes regardless of the dismissal path
    // (submit, cancel, or drag-down).
    if (!mounted) return;
    setState(() {
      _isSheetOpen = false;
      _markers = {};
    });
  }

  // ── AI Prediction ──────────────────────────────────────────────────────────

  void _showPredictionSheet(Position position) {
    // Scoped state for the bottom sheet
    _PredictionStatus sheetStatus = _PredictionStatus.idle;
    PredictionResponse? sheetResult;
    PredictionException? sheetError;

    // TODO: Replace placeholders with reverse-geocoding in a future phase
    const int kPlaceholderDistrict = 1;
    const int kPlaceholderCommunityArea = 1;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            void checkRisk() async {
              setModalState(() {
                sheetStatus = _PredictionStatus.loading;
                sheetError = null;
                sheetResult = null;
              });

              try {
                final request = PredictionRequest.fromDateTime(
                  dateTime: DateTime.now(),
                  latitude: position.latitude,
                  longitude: position.longitude,
                  district: kPlaceholderDistrict, 
                  communityArea: kPlaceholderCommunityArea,
                  locationDescription: 'STREET',
                );
                
                final errors = request.validate();
                if (errors.isNotEmpty) {
                  throw PredictionException(PredictionErrorType.validation, errors.first);
                }

                final result = await _predictionService.predict(request);

                setModalState(() {
                  sheetStatus = _PredictionStatus.success;
                  sheetResult = result;
                });
              } on PredictionException catch (e) {
                setModalState(() {
                  sheetStatus = _PredictionStatus.error;
                  sheetError = e;
                });
              } catch (e) {
                setModalState(() {
                  sheetStatus = _PredictionStatus.error;
                  sheetError = PredictionException(PredictionErrorType.server, 'Prediction failed. Please try again.');
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'AI Risk Prediction',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  PredictionResultCard(
                    result: sheetResult,
                    error: sheetError,
                    isLoading: sheetStatus == _PredictionStatus.loading,
                    onRetry: checkRisk,
                  ),
                  const SizedBox(height: 16),
                  if (sheetStatus == _PredictionStatus.idle)
                    ElevatedButton(
                      onPressed: checkRisk,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Analyze Current Location'),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Called by [ReportUnsafeZoneSheet] after a successful Firestore write.
  ///
  /// Shows a floating green SnackBar on the map screen. Called before
  /// [Navigator.pop] in the sheet so this screen's context is still valid.
  void _onReportSuccess() {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(child: Text('Unsafe zone reported successfully.')),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF22C55E), // green
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }

  // ── Build Helpers ──────────────────────────────────────────────────────────

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: _selectedCategories.isEmpty,
              onSelected: (_) => _onFilterChanged({}),
              showCheckmark: false,
              backgroundColor: Colors.white,
              selectedColor: AppTheme.primaryBlue.withOpacity(0.1),
              side: BorderSide(
                color: _selectedCategories.isEmpty
                    ? AppTheme.primaryBlue
                    : Colors.grey.shade300,
              ),
              labelStyle: TextStyle(
                color: _selectedCategories.isEmpty
                    ? AppTheme.primaryBlue
                    : Colors.black87,
                fontWeight: _selectedCategories.isEmpty
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          ...UnsafeZoneCategory.values.map((category) {
            final isSelected = _selectedCategories.contains(category);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(zoneCategoryLabel(category)),
                selected: isSelected,
                onSelected: (selected) {
                  final newSelection = Set<UnsafeZoneCategory>.from(
                    _selectedCategories,
                  );
                  if (selected) {
                    newSelection.add(category);
                  } else {
                    newSelection.remove(category);
                  }
                  _onFilterChanged(newSelection);
                },
                backgroundColor: Colors.white,
                selectedColor: AppTheme.primaryBlue.withOpacity(0.1),
                checkmarkColor: AppTheme.primaryBlue,
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.primaryBlue
                      : Colors.grey.shade300,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryBlue : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,

      appBar: AppBar(
        title: const Text('Community Map'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),

      body: Stack(
        children: [
          // ── Google Map ─────────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: _kDevelopmentFallbackPosition,
            myLocationEnabled: true,
            // The default Maps "my location" button is replaced by the
            // custom FAB below.
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            compassEnabled: true,
            // Suppress the default Maps toolbar (directions / open in Maps
            // buttons that appear when a marker is tapped).
            // Re-evaluate in Phase 12.4 when zone markers are introduced.
            mapToolbarEnabled: false,
            markers: {..._zoneMarkers, ..._markers},
            onLongPress: _onLongPress,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              // Attempt to center the map once the controller is ready.
              // If initState's call already resolved the position before
              // onMapCreated fired, this second call is a no-op (guarded
              // by _isLoadingLocation).
              _centerOnUserLocation();
            },
          ),

          // ── Filter Bar ─────────────────────────────────────────────────────
          Positioned(top: 0, left: 0, right: 0, child: _buildFilterBar()),

          // ── Loading indicator ──────────────────────────────────────────────
          if (_isLoadingLocation)
            const Positioned(
              top: 60, // Shifted down for filter bar
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 3,
                color: AppTheme.primaryBlue,
                backgroundColor: Colors.transparent,
              ),
            ),

          // ── Error banner ───────────────────────────────────────────────────
          if (_locationError != null)
            Positioned(
              top: 72, // Shifted down for filter bar
              left: 16,
              right: 16,
              child: _LocationErrorBanner(
                message: _locationError!,
                onDismiss: () => setState(() => _locationError = null),
              ),
            ),

          // ── Long-press hint overlay ────────────────────────────────────────
          //
          // Auto-dismisses after 4 seconds or on the user's first long press.
          // AnimatedOpacity keeps the widget in the tree so the fade-out
          // animation completes before the widget disappears.
          Positioned(
            bottom: 80,
            left: 16,
            right: 16,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _showHint ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                child: Center(
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.black87,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text(
                        'Long press on the map to report an unsafe location',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // ── Action FABs ────────────────────────────────────────────────────────
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'prediction_fab',
            backgroundColor: AppTheme.primaryBlue,
            elevation: 4,
            onPressed: () {
              if (_lastKnownPosition != null) {
                _showPredictionSheet(_lastKnownPosition!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wait for location fix...')),
                );
              }
            },
            icon: const Icon(Icons.analytics_outlined, color: Colors.white),
            label: const Text('Check Risk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'unsafe_zone_map_my_location_fab',
            backgroundColor: Colors.white,
            elevation: 4,
            onPressed: _centerOnUserLocation,
            tooltip: 'My location',
            child: const Icon(Icons.my_location_rounded, color: AppTheme.primaryBlue),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Location Error Banner
// ---------------------------------------------------------------------------

/// A dismissible in-map banner that surfaces GPS / permission errors.
///
/// Extracted into its own private widget to keep [_UnsafeZoneMapScreenState.build]
/// readable. This widget is stateless; dismissal is controlled by the parent
/// via [onDismiss].
class _LocationErrorBanner extends StatelessWidget {
  const _LocationErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.location_off_rounded,
              color: Color(
                0xFFFB923C,
              ), // orange — consistent with alertStatusColor('active')
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
