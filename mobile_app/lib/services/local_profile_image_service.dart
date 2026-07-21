import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LocalProfileImageService {
  /// Ensures the directory for the user's profile pictures exists.
  Future<Directory> _getUserDirectory(String uid) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final userDir = Directory('${docsDir.path}/profile_pictures/$uid');
    if (!await userDir.exists()) {
      await userDir.create(recursive: true);
    }
    return userDir;
  }

  /// Saves the source image file to the local persistent directory and returns the absolute path.
  Future<String> saveProfilePicture(String uid, String sourceFilePath) async {
    try {
      final userDir = await _getUserDirectory(uid);
      final destFile = File('${userDir.path}/avatar.jpg');
      
      // Copy the file from temporary location to permanent location
      final sourceFile = File(sourceFilePath);
      if (!await sourceFile.exists()) {
        throw Exception("Source file does not exist.");
      }
      
      await sourceFile.copy(destFile.path);
      debugPrint('[LocalProfileImageService] Saved avatar locally: ${destFile.path}');
      return destFile.path;
    } catch (e) {
      debugPrint('[LocalProfileImageService] Failed to save avatar: $e');
      rethrow;
    }
  }

  /// Returns the absolute path to the local avatar if it exists, otherwise null.
  Future<String?> getProfilePicturePath(String uid) async {
    try {
      final userDir = await _getUserDirectory(uid);
      final destFile = File('${userDir.path}/avatar.jpg');
      if (await destFile.exists()) {
        return destFile.path;
      }
    } catch (e) {
      debugPrint('[LocalProfileImageService] Failed to get avatar path: $e');
    }
    return null;
  }

  /// Deletes the local avatar if it exists.
  Future<void> deleteProfilePicture(String uid) async {
    try {
      final userDir = await _getUserDirectory(uid);
      final destFile = File('${userDir.path}/avatar.jpg');
      if (await destFile.exists()) {
        await destFile.delete();
        debugPrint('[LocalProfileImageService] Deleted avatar locally: ${destFile.path}');
      }
    } catch (e) {
      debugPrint('[LocalProfileImageService] Failed to delete avatar: $e');
      rethrow;
    }
  }
}
