import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum ProfileGender { male, female, preferNotToSay, other }

extension ProfileGenderExtension on ProfileGender {
  String toStorageString() {
    switch (this) {
      case ProfileGender.male: return 'male';
      case ProfileGender.female: return 'female';
      case ProfileGender.preferNotToSay: return 'prefer_not_to_say';
      case ProfileGender.other: return 'other';
    }
  }

  String get label {
    switch (this) {
      case ProfileGender.male: return 'Male';
      case ProfileGender.female: return 'Female';
      case ProfileGender.preferNotToSay: return 'Prefer not to say';
      case ProfileGender.other: return 'Other';
    }
  }

  static ProfileGender? fromString(String? raw) {
    if (raw == null) return null;
    switch (raw.toLowerCase()) {
      case 'male': return ProfileGender.male;
      case 'female': return ProfileGender.female;
      case 'prefer_not_to_say': return ProfileGender.preferNotToSay;
      case 'other': return ProfileGender.other;
      default: return null;
    }
  }
}

enum ProfileBloodGroup { aPos, aNeg, bPos, bNeg, abPos, abNeg, oPos, oNeg, unknown }

extension ProfileBloodGroupExtension on ProfileBloodGroup {
  String toStorageString() {
    switch (this) {
      case ProfileBloodGroup.aPos: return 'A+';
      case ProfileBloodGroup.aNeg: return 'A-';
      case ProfileBloodGroup.bPos: return 'B+';
      case ProfileBloodGroup.bNeg: return 'B-';
      case ProfileBloodGroup.abPos: return 'AB+';
      case ProfileBloodGroup.abNeg: return 'AB-';
      case ProfileBloodGroup.oPos: return 'O+';
      case ProfileBloodGroup.oNeg: return 'O-';
      case ProfileBloodGroup.unknown: return 'Unknown';
    }
  }

  String get label => toStorageString();

  static ProfileBloodGroup? fromString(String? raw) {
    if (raw == null) return null;
    switch (raw) {
      case 'A+': return ProfileBloodGroup.aPos;
      case 'A-': return ProfileBloodGroup.aNeg;
      case 'B+': return ProfileBloodGroup.bPos;
      case 'B-': return ProfileBloodGroup.bNeg;
      case 'AB+': return ProfileBloodGroup.abPos;
      case 'AB-': return ProfileBloodGroup.abNeg;
      case 'O+': return ProfileBloodGroup.oPos;
      case 'O-': return ProfileBloodGroup.oNeg;
      case 'Unknown': return ProfileBloodGroup.unknown;
      default: return null;
    }
  }
}

class UserProfileModel {
  final String uid;
  final String displayName;
  final String email;
  final String? phoneNumber;
  final String? photoURL;
  final String? localAvatarPath;
  final ProfileGender? gender;
  final ProfileBloodGroup? bloodGroup;
  final String? medicalNotes;
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
    this.localAvatarPath,
    this.gender,
    this.bloodGroup,
    this.medicalNotes,
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
  bool get hasAvatar => (photoURL != null && photoURL!.isNotEmpty) || (localAvatarPath != null);

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
      localAvatarPath: null,
      gender: ProfileGenderExtension.fromString(data['gender'] as String?),
      bloodGroup: ProfileBloodGroupExtension.fromString(data['bloodGroup'] as String?),
      medicalNotes: data['medicalNotes'] as String?,
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
      localAvatarPath: null,
      gender: null,
      bloodGroup: null,
      medicalNotes: null,
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
    String? photoURL,
    String? localAvatarPath,
    ProfileGender? gender,
    ProfileBloodGroup? bloodGroup,
    String? medicalNotes,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      phoneNumber: phoneNumber != null ? (phoneNumber.isEmpty ? null : phoneNumber) : this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      localAvatarPath: localAvatarPath ?? this.localAvatarPath,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      isVerified: isVerified,
      accountCreated: accountCreated,
      lastLogin: lastLogin,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      badges: badges,
    );
  }

  UserProfileModel withoutPhoto() {
    return UserProfileModel(
      uid: uid,
      displayName: displayName,
      email: email,
      phoneNumber: phoneNumber,
      photoURL: null,
      localAvatarPath: null,
      gender: gender,
      bloodGroup: bloodGroup,
      medicalNotes: medicalNotes,
      isVerified: isVerified,
      accountCreated: accountCreated,
      lastLogin: lastLogin,
      createdAt: createdAt,
      updatedAt: updatedAt,
      badges: badges,
    );
  }

  UserProfileModel withoutGender() {
    return UserProfileModel(
      uid: uid,
      displayName: displayName,
      email: email,
      phoneNumber: phoneNumber,
      photoURL: photoURL,
      localAvatarPath: localAvatarPath,
      gender: null,
      bloodGroup: bloodGroup,
      medicalNotes: medicalNotes,
      isVerified: isVerified,
      accountCreated: accountCreated,
      lastLogin: lastLogin,
      createdAt: createdAt,
      updatedAt: updatedAt,
      badges: badges,
    );
  }

  UserProfileModel withoutBloodGroup() {
    return UserProfileModel(
      uid: uid,
      displayName: displayName,
      email: email,
      phoneNumber: phoneNumber,
      photoURL: photoURL,
      localAvatarPath: localAvatarPath,
      gender: gender,
      bloodGroup: null,
      medicalNotes: medicalNotes,
      isVerified: isVerified,
      accountCreated: accountCreated,
      lastLogin: lastLogin,
      createdAt: createdAt,
      updatedAt: updatedAt,
      badges: badges,
    );
  }

  UserProfileModel withoutMedicalNotes() {
    return UserProfileModel(
      uid: uid,
      displayName: displayName,
      email: email,
      phoneNumber: phoneNumber,
      photoURL: photoURL,
      localAvatarPath: localAvatarPath,
      gender: gender,
      bloodGroup: bloodGroup,
      medicalNotes: null,
      isVerified: isVerified,
      accountCreated: accountCreated,
      lastLogin: lastLogin,
      createdAt: createdAt,
      updatedAt: updatedAt,
      badges: badges,
    );
  }
}
