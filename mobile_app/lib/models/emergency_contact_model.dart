import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyContactModel {
  final String id;
  final String displayName;
  final String phone;
  final String? relationship;
  final String? email;
  final bool isPrimary;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EmergencyContactModel({
    required this.id,
    required this.displayName,
    required this.phone,
    this.relationship,
    this.email,
    this.isPrimary = false,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// Derives 1-2 character initials from the display name for the avatar fallback.
  String get initials {
    if (displayName.trim().isEmpty) return '?';
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// Returns a clean string for phone numbers.
  String get formattedPhone => phone; // Simplification, could format E.164 here

  factory EmergencyContactModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final createdAtRaw = data['createdAt'];
    final updatedAtRaw = data['updatedAt'];

    final rawName = data['displayName'] as String? ?? data['name'] as String?;
    final resolvedName = (rawName != null && rawName.trim().isNotEmpty)
        ? rawName.trim()
        : 'Contact';

    final rawRelation = data['relationship'] as String? ??
        data['relation'] as String? ??
        data['role'] as String?;
    final resolvedRelation = (rawRelation != null && rawRelation.trim().isNotEmpty)
        ? rawRelation.trim()
        : null;

    return EmergencyContactModel(
      id: doc.id,
      displayName: resolvedName,
      phone: (data['phone'] as String? ?? '').trim(),
      relationship: resolvedRelation,
      email: (data['email'] as String? ?? '').trim().isNotEmpty ? (data['email'] as String).trim() : null,
      isPrimary: data['isPrimary'] as bool? ?? false,
      sortOrder: data['sortOrder'] as int? ?? 0,
      createdAt: createdAtRaw is Timestamp ? createdAtRaw.toDate() : null,
      updatedAt: updatedAtRaw is Timestamp ? updatedAtRaw.toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'phone': phone,
      if (relationship != null) 'relationship': relationship,
      if (email != null) 'email': email,
      'isPrimary': isPrimary,
      'sortOrder': sortOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  EmergencyContactModel copyWith({
    String? id,
    String? displayName,
    String? phone,
    String? relationship,
    String? email,
    bool? isPrimary,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyContactModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      email: email ?? this.email,
      isPrimary: isPrimary ?? this.isPrimary,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
