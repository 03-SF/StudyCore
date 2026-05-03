import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadAvatar(String userId, File imageFile) async {
    try {
      final ref = _storage.ref().child('avatars/$userId/profile.jpg');
      final task = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await task.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Could not upload photo. Check your connection.');
    }
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
