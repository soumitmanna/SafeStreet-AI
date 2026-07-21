import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../models/evidence_model.dart';
import 'communication_service.dart';
import 'emergency_contact_service.dart';

enum SosFailureType {
  unauthenticated,
  permissionDenied,
  permissionPermanentlyDenied,
  gpsDisabled,
  locationTimeout,
  firestoreFailure,
  unknown,
}

class SosException implements Exception {
  const SosException(
    this.message, {
    required this.type,
    this.cause,
  });

  final String message;
  final SosFailureType type;
  final Object? cause;

  @override
  String toString() => message;
}

class SosAlertResult {
  const SosAlertResult({
    required this.alertId,
    required this.latitude,
    required this.longitude,
    required this.location,
    this.contactsNotified = 0,
    this.smsFailedCount = 0,
  });

  final String alertId;
  final double latitude;
  final double longitude;
  final String location;
  final int contactsNotified;
  final int smsFailedCount;
}

class LocationInfo {
  const LocationInfo({
    required this.latitude,
    required this.longitude,
    required this.location,
    required this.mapsLink,
  });

  final double latitude;
  final double longitude;
  final String location;
  final String mapsLink;
}

class SosService {
  SosService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    EmergencyContactService? contactService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _contactService = contactService ?? EmergencyContactService();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final EmergencyContactService _contactService;

  Future<LocationInfo> resolveCurrentLocation() async {
    await _ensureLocationPermission();
    await _ensureGpsEnabled();

    final position = await _getCurrentPosition();
    return LocationInfo(
      latitude: position.latitude,
      longitude: position.longitude,
      location: _formatLocation(position),
      mapsLink: _buildMapsLink(position),
    );
  }

  Future<SosAlertResult> createActiveAlert({EvidenceModel? evidence}) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw const SosException(
        'Please sign in before sending an SOS alert.',
        type: SosFailureType.unauthenticated,
      );
    }

    final locationInfo = await resolveCurrentLocation();
    final alertRef = _firestore.collection('alerts').doc();
    final deviceTime = DateTime.now().toUtc().toIso8601String();

    final evidenceFields = evidence != null
        ? {
            'hasEvidence': true,
            'evidenceType': evidence.type.name,
            'evidenceFileName': evidence.fileName,
            'evidenceCapturedAt': evidence.capturedAt.toUtc().toIso8601String(),
            'deviceStored': true,
          }
        : {
            'hasEvidence': false,
          };

    try {
      await alertRef.set({
        'alertId': alertRef.id,
        'userId': user.uid,
        'displayName': user.displayName ?? '',
        'email': user.email ?? '',
        'latitude': locationInfo.latitude,
        'longitude': locationInfo.longitude,
        'mapsLink': locationInfo.mapsLink,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'deviceTime': deviceTime,
        'source': 'mobile',
        'userEmail': user.email ?? '',
        'location': locationInfo.location,
        'resolved': false,
        ...evidenceFields,
      });
    } on FirebaseException catch (error) {
      throw SosException(
        'SOS alert could not be saved. Please try again.',
        type: SosFailureType.firestoreFailure,
        cause: error,
      );
    } catch (error) {
      throw SosException(
        'SOS alert could not be created. Please try again.',
        type: SosFailureType.firestoreFailure,
        cause: error,
      );
    }

    final notificationResult = await _notifyTrustedContacts(
      location: locationInfo.location,
      mapsLink: locationInfo.mapsLink,
    );

    return SosAlertResult(
      alertId: alertRef.id,
      latitude: locationInfo.latitude,
      longitude: locationInfo.longitude,
      location: locationInfo.location,
      contactsNotified: notificationResult.contactsNotified,
      smsFailedCount: notificationResult.smsFailedCount,
    );
  }

  Future<void> _ensureLocationPermission() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const SosException(
        'Location permission denied. Please allow location access to send SOS.',
        type: SosFailureType.permissionDenied,
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const SosException(
        'Location permission is permanently denied. Enable it from app settings.',
        type: SosFailureType.permissionPermanentlyDenied,
      );
    }
  }

  Future<void> _ensureGpsEnabled() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw const SosException(
        'GPS is disabled. Turn on location services and try again.',
        type: SosFailureType.gpsDisabled,
      );
    }
  }

  Future<Position> _getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on TimeoutException catch (error) {
      throw SosException(
        'Location request timed out. Move to an open area and try again.',
        type: SosFailureType.locationTimeout,
        cause: error,
      );
    } on LocationServiceDisabledException catch (error) {
      throw SosException(
        'GPS is disabled. Turn on location services and try again.',
        type: SosFailureType.gpsDisabled,
        cause: error,
      );
    } on PermissionDeniedException catch (error) {
      throw SosException(
        'Location permission denied. Please allow location access to send SOS.',
        type: SosFailureType.permissionDenied,
        cause: error,
      );
    } catch (error) {
      throw SosException(
        'Could not fetch your current location. Please try again.',
        type: SosFailureType.unknown,
        cause: error,
      );
    }
  }

  Future<_NotificationResult> _notifyTrustedContacts({
    required String location,
    required String mapsLink,
  }) async {
    try {
      final contacts = await _contactService.getContactsForSOS();
      if (contacts.isEmpty) {
        return const _NotificationResult(contactsNotified: 0, smsFailedCount: 0);
      }

      final message = '''
🚨 EMERGENCY ALERT

I may be in danger.

This message was sent using SafeStreet.

Current Location:
$location

Please contact me immediately.
Maps: $mapsLink
''';

      var sentCount = 0;
      var failedCount = 0;

      for (final contact in contacts) {
        final phone = contact.phone.trim();
        if (phone.isEmpty) {
          continue;
        }

        try {
          await CommunicationService.sendSms(phone, message: message);
          sentCount += 1;
        } catch (_) {
          failedCount += 1;
        }
      }

      return _NotificationResult(
        contactsNotified: sentCount,
        smsFailedCount: failedCount,
      );
    } catch (_) {
      return const _NotificationResult(contactsNotified: 0, smsFailedCount: 0);
    }
  }

  String _formatLocation(Position position) {
    final latitude = position.latitude.toStringAsFixed(6);
    final longitude = position.longitude.toStringAsFixed(6);
    return '$latitude, $longitude';
  }

  String _buildMapsLink(Position position) {
    return 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
  }
}

class _NotificationResult {
  const _NotificationResult({
    required this.contactsNotified,
    required this.smsFailedCount,
  });

  final int contactsNotified;
  final int smsFailedCount;
}
