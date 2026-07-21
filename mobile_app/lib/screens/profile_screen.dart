import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/profile_controller.dart';
import '../models/user_profile_model.dart';
import '../services/contact_service.dart';
import '../widgets/profile_avatar_widget.dart';
import '../widgets/profile_badge_widget.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileController _controller;
  final ContactService _contactService = ContactService();

  @override
  void initState() {
    super.initState();
    _controller = ProfileController();
    _controller.loadProfile();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

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
        child: RefreshIndicator(
          onRefresh: _controller.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListenableBuilder(
                  listenable: _controller,
                  builder: (context, child) {
                    return _buildProfileHeader(theme, _controller.state);
                  },
                ),
                const SizedBox(height: 26),
                _buildEmergencyContacts(theme),
                const SizedBox(height: 24),
                const _SettingsSection(),
                const SizedBox(height: 28),
                _buildLogoutButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, ProfileState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black12),
      ),
      child: _buildHeaderContent(theme, state),
    );
  }

  Widget _buildHeaderContent(ThemeData theme, ProfileState state) {
    switch (state) {
      case ProfileLoading():
      case ProfileRetrying():
        return _buildLoadingSkeleton(theme);
        
      case ProfileLoaded(:final profile):
        return _buildLoadedHeader(theme, profile);
        
      case ProfileEmpty():
        return Column(
          children: [
            const Icon(Icons.person_outline, size: 48, color: Colors.black38),
            const SizedBox(height: 12),
            Text(
              'Incomplete profile',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
        
      case ProfileError(:final userMessage):
        return Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              userMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _controller.retry,
              child: const Text('Retry'),
            ),
          ],
        );
    }
  }

  Widget _buildLoadingSkeleton(ThemeData theme) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 40,
          backgroundColor: Color(0xFFE2E8F0),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 180,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 70,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 70,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadedHeader(ThemeData theme, UserProfileModel profile) {
    return Row(
      children: [
        ProfileAvatarWidget(profile: profile, radius: 40),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              if (profile.email.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  profile.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
              ],
              if (profile.hasBadges) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.badges.map((id) => ProfileBadgeWidget(badgeId: id)).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyContacts(ThemeData theme) {
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
          child: StreamBuilder<QuerySnapshot>(
            stream: _contactService.getContacts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: Text('Failed to load contacts')),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: Text('No contacts added', style: TextStyle(color: Colors.black54))),
                );
              }
              return Column(
                children: List.generate(docs.length, (index) {
                  final contact = docs[index].data() as Map<String, dynamic>;
                  final isLast = index == docs.length - 1;
                  return _buildContactRow(context, contact, isLast);
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(BuildContext context, Map<String, dynamic> contact, bool isLast) {
    final name = contact['name'] as String? ?? 'Unknown';
    final role = contact['role'] as String? ?? 'Contact';
    final phone = contact['phone'] as String? ?? '';
    
    final initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFE0F2FE),
            child: Text(
              initials,
              style: const TextStyle(color: Color(0xFF0369A1), fontWeight: FontWeight.w700),
            ),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('$role · $phone', style: const TextStyle(color: Colors.black54)),
          trailing: IconButton(
            icon: const Icon(Icons.call, color: Color(0xFF0EA5E9)),
            onPressed: () {},
          ),
        ),
        if (!isLast) const Divider(height: 0, indent: 18, endIndent: 18),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ElevatedButton(
      onPressed: _handleLogout,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const settings = [
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
}
