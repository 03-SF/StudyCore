import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String groupId;
  final String userId;
  final String senderName;
  final String? senderPhotoUrl;
  final String text;
  final String? imageUrl;
  final String? sharedDeckId;
  final String? sharedDeckName;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.text,
    this.imageUrl,
    this.sharedDeckId,
    this.sharedDeckName,
    required this.createdAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return MessageModel(
      id: id ?? map['id'] as String? ?? '',
      groupId: map['groupId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      senderPhotoUrl: map['senderPhotoUrl'] as String?,
      text: map['text'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      sharedDeckId: map['sharedDeckId'] as String?,
      sharedDeckName: map['sharedDeckName'] as String?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'userId': userId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'text': text,
      'imageUrl': imageUrl,
      'sharedDeckId': sharedDeckId,
      'sharedDeckName': sharedDeckName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  MessageModel copyWith({
    String? id,
    String? groupId,
    String? userId,
    String? senderName,
    String? senderPhotoUrl,
    String? text,
    String? imageUrl,
    String? sharedDeckId,
    String? sharedDeckName,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      sharedDeckId: sharedDeckId ?? this.sharedDeckId,
      sharedDeckName: sharedDeckName ?? this.sharedDeckName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
