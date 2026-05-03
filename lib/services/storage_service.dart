import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads avatar and reports progress via [onProgress] (0.0–1.0).
  /// Storage path matches firestore.rules: users/{userId}/avatar.jpg
  Future<String> uploadAvatar(
    String userId,
    File imageFile, {
    void Function(double)? onProgress,
  }) async {
    try {
      final ref = _storage.ref().child('users/$userId/avatar.jpg');
      final task = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      if (onProgress != null) {
        task.snapshotEvents.listen((snap) {
          if (snap.totalBytes > 0) {
            onProgress(snap.bytesTransferred / snap.totalBytes);
          }
        });
      }

      await task;
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Could not upload photo. Check your connection.');
    }
  }

  /// Deletes the avatar for [userId] from Storage. Silently ignores errors.
  Future<void> deleteAvatar(String userId) async {
    try {
      await _storage.ref().child('users/$userId/avatar.jpg').delete();
    } catch (_) {}
  }

  Future<String> uploadGroupPhoto(String groupId, File imageFile) async {
    try {
      final ref = _storage.ref().child('groups/$groupId/photo.jpg');
      final task = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await task.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Could not upload photo. Check your connection.');
    }
  }

  Future<String> uploadMessageImage(
      String groupId, String messageId, File imageFile) async {
    try {
      final ref =
          _storage.ref().child('groups/$groupId/messages/$messageId.jpg');
      final task = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await task.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Could not upload image. Check your connection.');
    }
  }

  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {}
  }
}
