import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String subject;
  final String adminId;
  final List<String> memberIds;
  final String? photoUrl;
  final bool isPublic;
  final int sharedDeckCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.subject,
    required this.adminId,
    required this.memberIds,
    this.photoUrl,
    required this.isPublic,
    required this.sharedDeckCount,
    required this.createdAt,
    required this.updatedAt,
  });

  int get memberCount => memberIds.length;

  factory GroupModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return GroupModel(
      id: id ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      subject: map['subject'] as String? ?? 'Other',
      adminId: map['adminId'] as String? ?? '',
      memberIds: List<String>.from(map['memberIds'] as List? ?? []),
      photoUrl: map['photoUrl'] as String?,
      isPublic: map['isPublic'] as bool? ?? true,
      sharedDeckCount: map['sharedDeckCount'] as int? ?? 0,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'subject': subject,
      'adminId': adminId,
      'memberIds': memberIds,
      'photoUrl': photoUrl,
      'isPublic': isPublic,
      'sharedDeckCount': sharedDeckCount,
      'memberCount': memberCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? subject,
    String? adminId,
    List<String>? memberIds,
    String? photoUrl,
    bool? isPublic,
    int? sharedDeckCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      adminId: adminId ?? this.adminId,
      memberIds: memberIds ?? this.memberIds,
      photoUrl: photoUrl ?? this.photoUrl,
      isPublic: isPublic ?? this.isPublic,
      sharedDeckCount: sharedDeckCount ?? this.sharedDeckCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
