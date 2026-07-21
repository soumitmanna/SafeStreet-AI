import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/repositories/notification_preference_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Test SharedPreferences Initialization', () async {
    try {
      SharedPreferences.setMockInitialValues({});
      final repo = NotificationPreferenceRepositoryImpl();
      final masterEnabled = await repo.getMasterEnabled();
      print('masterEnabled: $masterEnabled');
    } catch (e, stacktrace) {
      print('Exception caught in test: $e');
      print('Stacktrace: $stacktrace');
      rethrow;
    }
  });
}
