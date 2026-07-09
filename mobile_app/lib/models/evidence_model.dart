/// =============================================================
/// SafeStreet
/// Evidence Model
///
/// Represents a captured photo or video that can be attached
/// to an SOS alert.
///
/// Current Storage:
///   • Local Device
///
/// Future Upgrade:
///   • Firebase Storage
/// =============================================================

enum EvidenceType {
  image,
  video,
}

class EvidenceModel {
  /// Unique identifier
  final String id;

  /// Image or Video
  final EvidenceType type;

  /// Local file path
  final String filePath;

  /// Original file name
  final String fileName;

  /// File size in bytes
  final int fileSize;

  /// Date & Time when captured
  final DateTime capturedAt;

  /// Indicates whether the evidence
  /// has been uploaded to cloud storage.
  ///
  /// Currently always false because
  /// Phase 10 uses local storage only.
  final bool uploaded;

  /// Optional cloud URL
  final String? downloadUrl;

  const EvidenceModel({
    required this.id,
    required this.type,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.capturedAt,
    this.uploaded = false,
    this.downloadUrl,
  });

  /// Create a copy with updated fields.
  EvidenceModel copyWith({
    String? id,
    EvidenceType? type,
    String? filePath,
    String? fileName,
    int? fileSize,
    DateTime? capturedAt,
    bool? uploaded,
    String? downloadUrl,
  }) {
    return EvidenceModel(
      id: id ?? this.id,
      type: type ?? this.type,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      capturedAt: capturedAt ?? this.capturedAt,
      uploaded: uploaded ?? this.uploaded,
      downloadUrl: downloadUrl ?? this.downloadUrl,
    );
  }

  /// Convert model to JSON.
  ///
  /// Useful for future Firestore integration.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'filePath': filePath,
      'fileName': fileName,
      'fileSize': fileSize,
      'capturedAt': capturedAt.toIso8601String(),
      'uploaded': uploaded,
      'downloadUrl': downloadUrl,
    };
  }

  /// Create model from JSON.
  factory EvidenceModel.fromJson(Map<String, dynamic> json) {
    return EvidenceModel(
      id: json['id'] as String,
      type: json['type'] == 'video'
          ? EvidenceType.video
          : EvidenceType.image,
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String,
      fileSize: json['fileSize'] as int,
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      uploaded: json['uploaded'] as bool? ?? false,
      downloadUrl: json['downloadUrl'] as String?,
    );
  }

  @override
  String toString() {
    return '''
EvidenceModel(
  id: $id,
  type: ${type.name},
  fileName: $fileName,
  fileSize: $fileSize,
  uploaded: $uploaded
)
''';
  }
}

