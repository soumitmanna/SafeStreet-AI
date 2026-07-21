class NotificationPreferencesModel {
  final bool masterEnabled;
  final bool emergencyAlertEnabled;
  final bool sosConfirmationEnabled;

  const NotificationPreferencesModel({
    required this.masterEnabled,
    required this.emergencyAlertEnabled,
    required this.sosConfirmationEnabled,
  });

  factory NotificationPreferencesModel.defaults() {
    return const NotificationPreferencesModel(
      masterEnabled: true,
      emergencyAlertEnabled: true,
      sosConfirmationEnabled: true,
    );
  }

  bool isEffectivelyEnabled(bool categoryEnabled) => masterEnabled && categoryEnabled;

  NotificationPreferencesModel copyWith({
    bool? masterEnabled,
    bool? emergencyAlertEnabled,
    bool? sosConfirmationEnabled,
  }) {
    return NotificationPreferencesModel(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      emergencyAlertEnabled: emergencyAlertEnabled ?? this.emergencyAlertEnabled,
      sosConfirmationEnabled: sosConfirmationEnabled ?? this.sosConfirmationEnabled,
    );
  }
}
