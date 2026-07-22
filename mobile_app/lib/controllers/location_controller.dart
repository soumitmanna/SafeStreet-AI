import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/location_service.dart';
import '../services/emergency_contact_service.dart';
import '../repositories/location_repository.dart';
import '../repositories/location_repository_impl.dart';
import '../models/live_location_model.dart';
import '../models/emergency_contact_model.dart';

enum LocationState {
  idle,
  loading,
  trackingActive,
  permissionDenied,
  permissionPermanentlyDenied,
  gpsDisabled,
  error,
}

class LocationController extends ChangeNotifier {
  final LocationService _locationService;
  final LocationRepository _locationRepository;
  final EmergencyContactService _contactService;
  final FirebaseAuth _auth;

  LocationController({
    LocationService? locationService,
    LocationRepository? locationRepository,
    EmergencyContactService? contactService,
    FirebaseAuth? auth,
  })  : _locationService = locationService ?? LocationService(),
        _locationRepository = locationRepository ?? LocationRepositoryImpl(),
        _contactService = contactService ?? EmergencyContactService(),
        _auth = auth ?? FirebaseAuth.instance;

  LocationState _state = LocationState.idle;
  LocationState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  Placemark? _currentPlacemark;
  Placemark? get currentPlacemark => _currentPlacemark;

  List<EmergencyContactModel> _trustedContacts = [];
  List<EmergencyContactModel> get trustedContacts => _trustedContacts;

  StreamSubscription<Position>? _positionSubscription;

  void _setState(LocationState state, {String? error}) {
    _state = state;
    _errorMessage = error;
    notifyListeners();
  }

  Future<void> initialize() async {
    _setState(LocationState.loading);
    try {
      await _loadContacts();
      _currentPosition = await _locationService.getCurrentLocation();
      await _reverseGeocode(_currentPosition!);
      _setState(LocationState.idle);
    } on LocationDisabledException catch (e) {
      _setState(LocationState.gpsDisabled, error: e.message);
    } on LocationPermissionException catch (e) {
      if (e.isPermanentlyDenied) {
        _setState(LocationState.permissionPermanentlyDenied, error: e.message);
      } else {
        _setState(LocationState.permissionDenied, error: e.message);
      }
    } catch (e) {
      _setState(LocationState.error, error: e.toString());
    }
  }

  Future<void> refreshLocation() async {
    if (_state == LocationState.trackingActive) return;
    await initialize();
  }

  Future<void> _loadContacts() async {
    try {
      _trustedContacts = await _contactService.getContactsForSOS();
    } catch (e) {
      // Non-fatal if contacts fail to load
      debugPrint('Failed to load contacts: $e');
    }
  }

  Future<void> _reverseGeocode(Position position) async {
    final placemark = await _locationService.getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );
    _currentPlacemark = placemark;
  }

  Future<void> startLiveTracking() async {
    if (_state == LocationState.trackingActive) return;

    final user = _auth.currentUser;
    if (user == null) {
      _setState(LocationState.error, error: 'User not authenticated.');
      return;
    }

    _setState(LocationState.loading);

    try {
      await _locationService.ensurePermissions();
      _positionSubscription?.cancel();
      _positionSubscription = _locationService.streamPosition().listen(
        (Position position) {
          _currentPosition = position;
          _reverseGeocode(position).then((_) {
            notifyListeners();
          });
          
          final model = LiveLocationModel(
            uid: user.uid,
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
            heading: position.heading,
            speed: position.speed,
            updatedAt: DateTime.now(),
            isSharing: true,
          );
          _locationRepository.updateLiveLocation(user.uid, model).catchError((e) {
             debugPrint('Failed to broadcast location: $e');
          });
        },
        onError: (error) {
           debugPrint('Location stream error: $error');
           _handleStreamError(error);
        },
      );
      _setState(LocationState.trackingActive);
    } on LocationDisabledException catch (e) {
      _setState(LocationState.gpsDisabled, error: e.message);
    } on LocationPermissionException catch (e) {
      if (e.isPermanentlyDenied) {
        _setState(LocationState.permissionPermanentlyDenied, error: e.message);
      } else {
        _setState(LocationState.permissionDenied, error: e.message);
      }
    } catch (e) {
      _setState(LocationState.error, error: e.toString());
    }
  }

  void _handleStreamError(dynamic error) {
    stopLiveTracking();
    _setState(LocationState.error, error: 'Lost connection to location services.');
  }

  Future<void> stopLiveTracking() async {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    
    final user = _auth.currentUser;
    if (user != null) {
      await _locationRepository.stopLiveLocation(user.uid).catchError((_) {});
    }
    
    if (_state == LocationState.trackingActive) {
      _setState(LocationState.idle);
    }
  }

  Future<void> openAppSettings() async {
    await _locationService.openAppSettings();
  }

  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  @override
  void dispose() {
    stopLiveTracking();
    super.dispose();
  }
}
