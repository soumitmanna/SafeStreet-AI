import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/evidence_model.dart';

class EvidenceService {
  final ImagePicker _picker = ImagePicker();

  /// Capture a photo using the device camera.
  Future<EvidenceModel?> capturePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) return null;

      return await _saveEvidence(
        sourceFile: File(image.path),
        type: EvidenceType.image,
      );
    } catch (e) {
      throw Exception('Failed to capture photo: $e');
    }
  }

  /// Record a video using the device camera.
  Future<EvidenceModel?> recordVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 2),
      );

      if (video == null) return null;

      return await _saveEvidence(
        sourceFile: File(video.path),
        type: EvidenceType.video,
      );
    } catch (e) {
      throw Exception('Failed to record video: $e');
    }
  }

  /// Save captured media into the application's local storage.
  Future<EvidenceModel> _saveEvidence({
    required File sourceFile,
    required EvidenceType type,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();

    final evidenceDir = Directory(
      path.join(appDir.path, 'evidence'),
    );

    if (!await evidenceDir.exists()) {
      await evidenceDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final extension = path.extension(sourceFile.path);

    final filename =
        '${type.name}_$timestamp$extension';

    final destination = path.join(
      evidenceDir.path,
      filename,
    );

    final savedFile = await sourceFile.copy(destination);

    return EvidenceModel(
      id: timestamp.toString(),
      type: type,
      filePath: savedFile.path,
      fileName: filename,
      fileSize: await savedFile.length(),
      capturedAt: DateTime.now(),
    );
  }

  /// Delete an evidence file from local storage.
  Future<void> deleteEvidence(EvidenceModel evidence) async {
    final file = File(evidence.filePath);

    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Check if the evidence file still exists.
  Future<bool> exists(EvidenceModel evidence) async {
    return File(evidence.filePath).exists();
  }
}

