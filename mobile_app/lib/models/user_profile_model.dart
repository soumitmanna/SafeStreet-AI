import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileModel {
  final String uid;
  final String displayName;
  final String email;
  final String? phoneNumber;
  final String? photoURL;
  final bool isVerified;
  final DateTime? accountCreated;
  final DateTime? lastLogin;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> badges;

  const UserProfileModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.phoneNumber,
    this.photoURL,
    required this.isVerified,
    this.accountCreated,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
    this.badges = const [],
  });

  /// Derives 1-2 character initials from the display name.
  String get initials {
    if (displayName.trim().isEmpty || displayName == 'User') return '?';
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// Whether the user has an avatar URL.
  bool get hasAvatar => photoURL != null && photoURL!.isNotEmpty;

  /// Whether the user has a phone number.
  bool get hasPhone => phoneNumber != null && phoneNumber!.isNotEmpty;

  /// Whether the user has any badges.
  bool get hasBadges => badges.isNotEmpty;

  /// Parses a Firestore document into a [UserProfileModel].
  factory UserProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final accountCreatedRaw = data['accountCreated'];
    final lastLoginRaw = data['lastLogin'];
    final createdAtRaw = data['createdAt'];
    final updatedAtRaw = data['updatedAt'];

    final rawBadges = data['badges'];
    final List<String> parsedBadges = rawBadges is List
        ? rawBadges.map((e) => e.toString()).toList()
        : [];

    return UserProfileModel(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? 'User',
      email: data['email'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String?,
      photoURL: data['photoURL'] as String?,
      isVerified: data['isVerified'] as bool? ?? false,
      accountCreated: accountCreatedRaw != null
          ? (accountCreatedRaw as Timestamp).toDate()
          : null,
      lastLogin: lastLoginRaw != null
          ? (lastLoginRaw as Timestamp).toDate()
          : null,
      createdAt: createdAtRaw != null
          ? (createdAtRaw as Timestamp).toDate()
          : null,
      updatedAt: updatedAtRaw != null
          ? (updatedAtRaw as Timestamp).toDate()
          : null,
      badges: parsedBadges,
    );
  }

  /// Fallback parsing directly from Firebase Auth user.
  factory UserProfileModel.fromAuth(User user) {
    return UserProfileModel(
      uid: user.uid,
      displayName: user.displayName ?? (user.isAnonymous ? 'Guest' : 'User'),
      email: user.email ?? '',
      phoneNumber: user.phoneNumber,
      photoURL: user.photoURL,
      isVerified: user.emailVerified,
      accountCreated: user.metadata.creationTime,
      lastLogin: user.metadata.lastSignInTime,
      createdAt: null,
      updatedAt: null,
      badges: [],
    );
  }

  /// Empty state model.
  factory UserProfileModel.empty() {
    return const UserProfileModel(
      uid: '',
      displayName: '',
      email: '',
      isVerified: false,
    );
  }

  /// Creates a copy of this model with the given fields replaced with the new values.
  UserProfileModel copyWith({
    String? displayName,
    String? phoneNumber,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      phoneNumber: phoneNumber != null ? (phoneNumber.isEmpty ? null : phoneNumber) : this.phoneNumber,
      photoURL: photoURL,
      isVerified: isVerified,
      accountCreated: accountCreated,
      lastLogin: lastLogin,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      badges: badges,
    );
  }
}
