import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationPermissionException implements Exception {
  final String message;
  final bool isPermanentlyDenied;
  LocationPermissionException(this.message, {this.isPermanentlyDenied = false});

  @override
  String toString() => message;
}

class LocationDisabledException implements Exception {
  final String message;
  LocationDisabledException(this.message);

  @override
  String toString() => message;
}

class LocationService {
  /// Checks and requests location permissions. Throws specific exceptions on failure.
  Future<void> ensurePermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationDisabledException('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw LocationPermissionException('Location permission denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionException(
        'Location permission permanently denied. Please enable it in settings.',
        isPermanentlyDenied: true,
      );
    }
  }

  /// Opens the device app settings so the user can grant permanently denied permissions.
  Future<bool> openAppSettings() async {
    return Geolocator.openAppSettings();
  }
  
  /// Opens the device location settings so the user can enable GPS.
  Future<bool> openLocationSettings() async {
    return Geolocator.openLocationSettings();
  }

  /// Gets the current location, ensuring permissions first.
  Future<Position> getCurrentLocation() async {
    await ensurePermissions();
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  /// Returns a stream of position updates.
  Stream<Position> streamPosition() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // emit only when user moves >= 10 m
      ),
    );
  }

  /// Reverse geocodes coordinates into a Placemark. Returns null if it fails (e.g. offline).
  Future<Placemark?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final geocoding = Geocoding();
      final placemarks = await geocoding.placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        return placemarks.first;
      }
    } catch (e) {
      // Ignored: geocoding failed (likely due to no internet/offline).
    }
    return null;
  }
}
