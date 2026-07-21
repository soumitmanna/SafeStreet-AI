abstract class NotificationPreferenceRepository {
  Future<bool> getMasterEnabled();
  Future<bool> getEmergencyAlertEnabled();
  Future<bool> getSosConfirmationEnabled();
  Future<void> setMasterEnabled(bool value);
  Future<void> setEmergencyAlertEnabled(bool value);
  Future<void> setSosConfirmationEnabled(bool value);
}
