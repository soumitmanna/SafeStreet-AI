import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/account_settings_controller.dart';
import '../widgets/settings_section_header.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_toggle_tile.dart';
import '../theme/app_theme.dart';

class SecurityScreen extends StatelessWidget {
  final AccountSettingsController controller;
  
  const SecurityScreen({super.key, required this.controller});

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This feature is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Unknown';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Security'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const SettingsSectionHeader(title: 'Authentication'),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                SettingsTile(
                  icon: Icons.account_circle_outlined,
                  title: 'Signed in as',
                  subtitle: email,
                  trailing: const SizedBox.shrink(), // No chevron
                  onTap: null, // Read-only
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SettingsTile(
                  icon: Icons.fingerprint_rounded,
                  title: 'Biometric Authentication',
                  subtitle: 'Use Face ID / Touch ID',
                  onTap: () => _showComingSoon(context),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          const SettingsSectionHeader(title: 'Emergency'),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, child) {
                final notifState = controller.notificationState;
                if (notifState is AccountSettingsNotificationLoaded) {
                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      SettingsToggleTile(
                        icon: Icons.check_circle_rounded,
                        title: 'SOS Confirmation',
                        subtitle: 'Confirm before sending SOS',
                        value: notifState.prefs.sosConfirmationEnabled,
                        enabled: notifState.prefs.masterEnabled,
                        onChanged: controller.setSosConfirmationNotifications,
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                }
                return const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          
          const SettingsSectionHeader(title: 'Device'),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                SettingsTile(
                  icon: Icons.phonelink_lock_outlined,
                  title: 'Device Security',
                  subtitle: 'Device Security Unknown',
                  iconColor: Theme.of(context).extension<AppStatusColors>()?.warning,
                  trailing: Icon(Icons.info_outline_rounded, color: Theme.of(context).extension<AppStatusColors>()?.warning),
                  onTap: () => _showComingSoon(context),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
