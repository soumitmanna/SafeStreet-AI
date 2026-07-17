class PredictionRequest {
  final double latitude;
  final double longitude;
  final int hour;
  final int dayOfWeek;
  final int month;
  final int district;
  final int communityArea;
  final String locationDescription;

  PredictionRequest({
    required this.latitude,
    required this.longitude,
    required this.hour,
    required this.dayOfWeek,
    required this.month,
    required this.district,
    required this.communityArea,
    required this.locationDescription,
  });

  /// Validates the request fields for Flutter UI before sending.
  /// Returns a list of error messages. Empty list means valid.
  List<String> validate() {
    final errors = <String>[];

    if (latitude < -90.0 || latitude > 90.0) {
      errors.add('Latitude must be between -90.0 and 90.0');
    }
    if (longitude < -180.0 || longitude > 180.0) {
      errors.add('Longitude must be between -180.0 and 180.0');
    }
    if (hour < 0 || hour > 23) {
      errors.add('Hour must be between 0 and 23');
    }
    if (dayOfWeek < 0 || dayOfWeek > 6) {
      errors.add('Day of week must be between 0 and 6');
    }
    if (month < 1 || month > 12) {
      errors.add('Month must be between 1 and 12');
    }
    if (district <= 0) {
      errors.add('District must be greater than 0');
    }
    if (communityArea <= 0) {
      errors.add('Community area must be greater than 0');
    }
    if (locationDescription.trim().isEmpty) {
      errors.add('Location description cannot be empty');
    }

    return errors;
  }

  /// Convenience factory to automatically extract time components from a DateTime.
  factory PredictionRequest.fromDateTime({
    required DateTime dateTime,
    required double latitude,
    required double longitude,
    required int district,
    required int communityArea,
    required String locationDescription,
  }) {
    // Dart's DateTime.weekday is 1 (Monday) to 7 (Sunday).
    // FastAPI schema expects 0 (Monday) to 6 (Sunday).
    final dayOfWeek = dateTime.weekday - 1;
    
    return PredictionRequest(
      latitude: latitude,
      longitude: longitude,
      hour: dateTime.hour,
      dayOfWeek: dayOfWeek,
      month: dateTime.month,
      district: district,
      communityArea: communityArea,
      locationDescription: locationDescription,
    );
  }

  /// Serializes the request to JSON, mapping Dart camelCase to FastAPI snake_case.
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'hour': hour,
      'day_of_week': dayOfWeek,
      'month': month,
      'district': district,
      'community_area': communityArea,
      'location_description': locationDescription,
    };
  }
}
