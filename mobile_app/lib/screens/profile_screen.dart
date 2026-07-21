import 'package:flutter/material.dart';
import '../controllers/profile_controller.dart';
import '../models/user_profile_model.dart';
import '../models/emergency_contact_model.dart';
import '../services/emergency_contact_service.dart';
import '../widgets/profile_avatar_widget.dart';
import '../widgets/profile_badge_widget.dart';
import 'edit_profile_screen.dart';
import 'account_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileController _controller;
  final EmergencyContactService _contactService = EmergencyContactService();

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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AccountSettingsScreen(
                    profileController: _controller,
                  ),
                ),
              );
            },
          ),
        ],
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
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.black54),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProfileScreen(
                  profile: profile,
                  profileController: _controller,
                ),
              ),
            );
            if (result == true) {
              _controller.loadProfile();
            }
          },
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
          child: StreamBuilder<List<EmergencyContactModel>>(
            stream: _contactService.streamContacts(),
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
              final contacts = snapshot.data ?? [];
              if (contacts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: Text('No contacts added', style: TextStyle(color: Colors.black54))),
                );
              }
              return Column(
                children: List.generate(contacts.length, (index) {
                  final contact = contacts[index];
                  final isLast = index == contacts.length - 1;
                  return _buildContactRow(context, contact, isLast);
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(BuildContext context, EmergencyContactModel contact, bool isLast) {
    final name = contact.displayName;
    final relationship = contact.relationship?.trim().isNotEmpty == true
        ? contact.relationship!
        : 'Trusted contact';
    final phone = contact.formattedPhone;

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFE0F2FE),
            child: Text(
              contact.initials,
              style: const TextStyle(color: Color(0xFF0369A1), fontWeight: FontWeight.w700),
            ),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (contact.isPrimary) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Primary',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0369A1),
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text('$relationship · $phone', style: const TextStyle(color: Colors.black54)),
          trailing: IconButton(
            icon: const Icon(Icons.call, color: Color(0xFF0EA5E9)),
            onPressed: () async {
              try {
                await _contactService.callContact(contact);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not initiate call: ${contact.displayName}')),
                  );
                }
              }
            },
          ),
        ),
        if (!isLast) const Divider(height: 0, indent: 18, endIndent: 18),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const settings = [
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
