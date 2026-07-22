import 'package:flutter/material.dart';
import '../controllers/account_settings_controller.dart';
import '../services/account_settings_service.dart';
import '../widgets/settings_section_header.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_toggle_tile.dart';
import '../widgets/settings_destructive_tile.dart';
import '../widgets/profile_avatar_widget.dart';
import 'edit_profile_screen.dart';
import 'appearance_screen.dart';
import 'privacy_screen.dart';
import 'security_screen.dart';
import 'support_screen.dart';
import 'login_screen.dart';
import '../controllers/profile_controller.dart';

class AccountSettingsScreen extends StatefulWidget {
  final ProfileController profileController;
  
  const AccountSettingsScreen({super.key, required this.profileController});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  late final AccountSettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AccountSettingsController();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _controller.logout();
      if (mounted) {
        // Clear entire navigation stack and go to Login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } on SettingsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Account Settings'),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          final state = _controller.state;
          
          if (state is AccountSettingsLoading || state is AccountSettingsIdle) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is AccountSettingsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text(state.error.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _controller.initialize,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (state is AccountSettingsLoaded) {
            final profile = state.profile;
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                const SettingsSectionHeader(title: 'Account'),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            ProfileAvatarWidget(profile: profile, radius: 32),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  if (profile.email.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      profile.email,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      SettingsTile(
                        icon: Icons.edit_outlined,
                        title: 'Edit Profile',
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(
                                profile: profile,
                                profileController: widget.profileController,
                              ),
                            ),
                          );
                          if (result == true) {
                            _controller.initialize(); // Refresh profile info
                            widget.profileController.loadProfile(); // Keep profile screen in sync
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                const SettingsSectionHeader(title: 'Notifications'),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: _buildNotificationSection(context, _controller.notificationState),
                ),
                const SettingsSectionHeader(title: 'Settings'),
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
                        icon: Icons.palette_outlined,
                        title: 'Appearance',
                        subtitle: 'Theme and display settings',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AppearanceScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      SettingsTile(
                        icon: Icons.lock_outline_rounded,
                        title: 'Privacy',
                        subtitle: 'Manage permissions and data',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PrivacyScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      SettingsTile(
                        icon: Icons.shield_outlined,
                        title: 'Security',
                        subtitle: 'Authentication and emergency features',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SecurityScreen(
                                controller: _controller,
                              ),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      SettingsTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Support',
                        subtitle: 'Help center and about',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SupportScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      SettingsDestructiveTile(
                        icon: Icons.logout_rounded,
                        title: 'Logout',
                        onTap: _handleLogout,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildNotificationSection(BuildContext context, AccountSettingsNotificationState notifState) {
    if (notifState is AccountSettingsNotificationLoading) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (notifState is AccountSettingsNotificationError) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(child: Text(notifState.error, style: TextStyle(color: Theme.of(context).colorScheme.error))),
      );
    }
    
    if (notifState is AccountSettingsNotificationLoaded) {
      final prefs = notifState.prefs;
      return Column(
        children: [
          SettingsToggleTile(
            icon: Icons.notifications_active_rounded,
            title: 'Allow Notifications',
            subtitle: 'Master toggle for all alerts',
            value: prefs.masterEnabled,
            onChanged: _controller.setMasterNotificationEnabled,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SettingsToggleTile(
            icon: Icons.warning_rounded,
            title: 'Emergency Alerts',
            subtitle: 'Receive alerts from nearby users',
            value: prefs.emergencyAlertEnabled,
            enabled: prefs.masterEnabled,
            onChanged: _controller.setEmergencyAlertNotifications,
          ),
          const SizedBox(height: 8),
        ],
      );
    }
    
    return const SizedBox.shrink();
  }
}
