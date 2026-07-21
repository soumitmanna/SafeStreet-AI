import '../models/notification_preferences_model.dart';
import '../repositories/notification_preference_repository.dart';
import '../repositories/notification_preference_repository_impl.dart';

class NotificationPreferenceService {
  final NotificationPreferenceRepository _repository;

  NotificationPreferenceService({NotificationPreferenceRepository? repository})
      : _repository = repository ?? NotificationPreferenceRepositoryImpl();

  Future<NotificationPreferencesModel> loadPreferences() async {
    final master = await _repository.getMasterEnabled();
    final emergencyAlert = await _repository.getEmergencyAlertEnabled();
    final sosConfirmation = await _repository.getSosConfirmationEnabled();

    return NotificationPreferencesModel(
      masterEnabled: master,
      emergencyAlertEnabled: emergencyAlert,
      sosConfirmationEnabled: sosConfirmation,
    );
  }

  Future<void> setMasterEnabled(bool value) async {
    await _repository.setMasterEnabled(value);
  }

  Future<void> setEmergencyAlertEnabled(bool value) async {
    await _repository.setEmergencyAlertEnabled(value);
  }

  Future<void> setSosConfirmationEnabled(bool value) async {
    await _repository.setSosConfirmationEnabled(value);
  }
}
