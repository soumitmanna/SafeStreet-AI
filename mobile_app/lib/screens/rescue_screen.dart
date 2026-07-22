import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class RescueScreen extends StatefulWidget {
  final String alertId;

  const RescueScreen({
    super.key,
    required this.alertId,
  });

  @override
  State<RescueScreen> createState() => _RescueScreenState();
}

class _RescueScreenState extends State<RescueScreen> {
  GoogleMapController? _mapController;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Set<Marker> _markers = {};

  Position? _currentPosition;
  double? _distanceInMeters;
  String _eta = "--";

  static const CameraPosition _initialPosition =
      CameraPosition(
    target: LatLng(22.5726, 88.3639),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) return;

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final position =
        await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    _currentPosition = position;

    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId("volunteer"),
          position: LatLng(
            position.latitude,
            position.longitude,
          ),
          infoWindow: const InfoWindow(
            title: "You",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    });

    _listenVictimLocation();
  }

  void _listenVictimLocation() {
    _firestore
        .collection('alerts')
        .doc(widget.alertId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;

      final data = doc.data();

      if (data == null) return;

      final lat = data["latitude"];
      final lng = data["longitude"];

      if (lat == null || lng == null) return;

      final LatLng victimPosition = LatLng(
        (lat as num).toDouble(),
        (lng as num).toDouble(),
      );

      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        victimPosition.latitude,
        victimPosition.longitude,
      );

      const double averageSpeed = 5.0;

      final minutes =
          (distance / averageSpeed / 60).ceil();

      final Set<Marker> updatedMarkers = {
        Marker(
          markerId: const MarkerId("victim"),
          position: victimPosition,
          infoWindow: const InfoWindow(
            title: "Victim",
          ),
        ),
        Marker(
          markerId: const MarkerId("volunteer"),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: const InfoWindow(
            title: "You",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      };

      setState(() {
        _distanceInMeters = distance;
        _eta = "$minutes min";
        _markers = updatedMarkers;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(victimPosition),
      );
    });
  }

  Future<void> _openNavigation() async {
    if (_markers.isEmpty) return;

    Marker? victimMarker;

    try {
      victimMarker = _markers.firstWhere(
        (marker) => marker.markerId.value == "victim",
      );
    } catch (_) {
      return;
    }

    final lat = victimMarker.position.latitude;
    final lng = victimMarker.position.longitude;

    final Uri url = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving",
    );

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Rescue",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(20),
              child: SizedBox(
                height: 320,
                child: GoogleMap(
                  initialCameraPosition:
                      _initialPosition,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Rescue in Progress",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            if (_distanceInMeters == null)
              Text(
                "Live tracking is active.",
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        "Distance : ${(_distanceInMeters! / 1000).toStringAsFixed(2)} km",
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        "ETA : $_eta",
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),

            const Spacer(),

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _openNavigation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                icon: const Icon(Icons.navigation),
                label: const Text(
                  "Navigate",
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}