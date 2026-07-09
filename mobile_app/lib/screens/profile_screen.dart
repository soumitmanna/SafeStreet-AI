import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileHeader(theme),
              const SizedBox(height: 26),
              _buildEmergencyContacts(
  context,
  theme,
),
              const SizedBox(height: 24),
              _buildSettingsSection(theme),
              const SizedBox(height: 28),
              _buildLogoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFE0E7FF),
            child: Text(
              'SM',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF3730A3),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Soumit Manna',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'soumit@example.com',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildStatusChip('Verified', const Color(0xFFDCFCE7), const Color(0xFF166534)),
                    const SizedBox(width: 8),
                    _buildStatusChip('Priority', const Color(0xFFFEF3C7), const Color(0xFF92400E)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color background, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildEmergencyContacts(
  BuildContext context,
  ThemeData theme,
) {
    final contacts = const [
      {'name': 'Ariana Patel', 'role': 'Family', 'phone': '+1 555 283 910'},
      {'name': 'Noah Chen', 'role': 'Friend', 'phone': '+1 555 721 844'},
      {'name': 'Ethan Reid', 'role': 'Safety', 'phone': '+1 555 110 332'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency contacts',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            children: contacts.map((contact) => _buildContactRow(context, contact)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(BuildContext context, Map<String, String> contact) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFE0F2FE),
            child: Text(
              contact['name']!.split(' ').map((word) => word[0]).take(2).join(),
              style: const TextStyle(color: Color(0xFF0369A1), fontWeight: FontWeight.w700),
            ),
          ),
          title: Text(contact['name']!, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${contact['role']} · ${contact['phone']}', style: const TextStyle(color: Colors.black54)),
          trailing: IconButton(
            icon: const Icon(Icons.call, color: Color(0xFF0EA5E9)),
            onPressed: () {},
          ),
        ),
        if (contact != const {'name': 'Ethan Reid', 'role': 'Safety', 'phone': '+1 555 110 332'})
          const Divider(height: 0, indent: 18, endIndent: 18),
      ],
    );
  }

  Widget _buildSettingsSection(ThemeData theme) {
    final settings = const [
      {'icon': Icons.notifications_rounded, 'title': 'Notifications', 'subtitle': 'Alert preferences'},
      {'icon': Icons.lock_rounded, 'title': 'Privacy', 'subtitle': 'Manage permissions'},
      {'icon': Icons.shield_rounded, 'title': 'Security', 'subtitle': 'Emergency access settings'},
      {'icon': Icons.help_outline_rounded, 'title': 'Support', 'subtitle': 'Help center'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            children: settings
                .map(
                  (setting) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDEAFE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(setting['icon'] as IconData, color: const Color(0xFF2563EB)),
                    ),
                    title: Text(setting['title'] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(setting['subtitle'] as String, style: const TextStyle(color: Colors.black54)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black38),
                    onTap: () {},
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
