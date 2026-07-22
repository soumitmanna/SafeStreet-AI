import '../models/live_location_model.dart';

abstract class LocationRepository {
  /// Broadcasts the user's current live location to Firestore.
  Future<void> updateLiveLocation(String uid, LiveLocationModel location);

  /// Stops broadcasting the user's live location.
  Future<void> stopLiveLocation(String uid);

  /// Streams a specific user's live location (e.g. for a trusted contact).
  Stream<LiveLocationModel?> streamUserLocation(String uid);
}
