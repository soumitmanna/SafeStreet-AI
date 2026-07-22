import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/live_location_model.dart';
import 'location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  final FirebaseFirestore _firestore;

  LocationRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> updateLiveLocation(String uid, LiveLocationModel location) async {
    await _firestore
        .collection('live_tracking')
        .doc(uid)
        .set(location.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> stopLiveLocation(String uid) async {
    await _firestore.collection('live_tracking').doc(uid).update({
      'isSharing': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<LiveLocationModel?> streamUserLocation(String uid) {
    return _firestore
        .collection('live_tracking')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return LiveLocationModel.fromFirestore(snapshot);
    });
  }
}
