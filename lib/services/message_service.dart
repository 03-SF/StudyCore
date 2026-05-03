import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Stream<List<MessageModel>> messagesStream(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MessageModel.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  Future<void> sendMessage({
    required String groupId,
    required String userId,
    required String senderName,
    String? senderPhotoUrl,
    required String text,
    String? imageUrl,
    String? sharedDeckId,
    String? sharedDeckName,
  }) async {
    final id = _uuid.v4();
    final message = MessageModel(
      id: id,
      groupId: groupId,
      userId: userId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      text: text,
      imageUrl: imageUrl,
      sharedDeckId: sharedDeckId,
      sharedDeckName: sharedDeckName,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .doc(id)
        .set(message.toMap());
  }

  Future<void> deleteMessage(String groupId, String messageId) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  Future<List<MessageModel>> loadMoreMessages(
      String groupId, DocumentSnapshot lastDoc) async {
    final snap = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .startAfterDocument(lastDoc)
        .limit(50)
        .get();
    return snap.docs
        .map((doc) => MessageModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }
}
