import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/settings_section_header.dart';
import '../widgets/settings_tile.dart';
import '../widgets/permission_tile.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Privacy'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const SettingsSectionHeader(title: 'Permissions'),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: const Column(
              children: [
                SizedBox(height: 8),
                PermissionTile(
                  icon: Icons.location_on_outlined,
                  title: 'Location Permission',
                  subtitle: 'Used for SOS tracking and maps',
                  permission: Permission.location,
                ),
                Divider(height: 1, indent: 16, endIndent: 16),
                PermissionTile(
                  icon: Icons.camera_alt_outlined,
                  title: 'Camera Permission',
                  subtitle: 'Used to capture incident evidence',
                  permission: Permission.camera,
                ),
                Divider(height: 1, indent: 16, endIndent: 16),
                PermissionTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Photo Library',
                  subtitle: 'Used to upload profile pictures',
                  permission: Permission.photos,
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const SettingsSectionHeader(title: 'Legal'),
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
                  icon: Icons.description_outlined,
                  title: 'Privacy Policy',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SettingsTile(
                  icon: Icons.gavel_outlined,
                  title: 'Terms & Conditions',
                  onTap: () {},
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const SettingsSectionHeader(title: 'Data'),
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
                  icon: Icons.analytics_outlined,
                  title: 'Data Collection Information',
                  subtitle: 'Learn how your data is used',
                  onTap: () {},
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
