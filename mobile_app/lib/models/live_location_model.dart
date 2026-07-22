import 'package:cloud_firestore/cloud_firestore.dart';

class LiveLocationModel {
  final String uid;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double heading;
  final double speed;
  final DateTime updatedAt;
  final bool isSharing;

  const LiveLocationModel({
    required this.uid,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.heading,
    required this.speed,
    required this.updatedAt,
    required this.isSharing,
  });

  factory LiveLocationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final updateTimeRaw = data['updatedAt'];

    return LiveLocationModel(
      uid: doc.id,
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (data['accuracy'] as num?)?.toDouble() ?? 0.0,
      heading: (data['heading'] as num?)?.toDouble() ?? 0.0,
      speed: (data['speed'] as num?)?.toDouble() ?? 0.0,
      updatedAt: updateTimeRaw != null
          ? (updateTimeRaw as Timestamp).toDate()
          : DateTime.now(),
      isSharing: data['isSharing'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'heading': heading,
      'speed': speed,
      'updatedAt': FieldValue.serverTimestamp(),
      'isSharing': isSharing,
    };
  }
}
