import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_app/repositories/notification_preference_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Test SharedPreferences Initialization', () async {
    try {
      SharedPreferences.setMockInitialValues({});
      final repo = NotificationPreferenceRepositoryImpl();
      final masterEnabled = await repo.getMasterEnabled();
      debugPrint('masterEnabled: $masterEnabled');
    } catch (e, stacktrace) {
      debugPrint('Exception caught in test: $e');
      debugPrint('Stacktrace: $stacktrace');
      rethrow;
    }
  });
}
