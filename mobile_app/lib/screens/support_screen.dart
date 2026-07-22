import 'package:flutter/material.dart';
import '../widgets/settings_section_header.dart';
import '../widgets/settings_tile.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This feature is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const SettingsSectionHeader(title: 'Help & Contact'),
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
                  icon: Icons.help_center_outlined,
                  title: 'Help Center',
                  subtitle: 'Coming soon',
                  onTap: () => _showComingSoon(context),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SettingsTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Contact Support',
                  subtitle: 'Reach out to our team',
                  onTap: () => _showComingSoon(context),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          const SettingsSectionHeader(title: 'About'),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: const Column(
              children: [
                SizedBox(height: 8),
                SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'App Version',
                  subtitle: '1.0.0 (Build 1)',
                  trailing: SizedBox.shrink(), // No chevron
                  onTap: null, // Read-only
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
