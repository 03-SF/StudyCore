import 'package:cloud_firestore/cloud_firestore.dart';

class DeckModel {
  final String id;
  final String userId;
  final String name;
  final String description;
  final String subject;
  final String accentColorHex;
  final int cardCount;
  final int dueCount;
  final double masteryPercent;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DeckModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.subject,
    required this.accentColorHex,
    required this.cardCount,
    required this.dueCount,
    required this.masteryPercent,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeckModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return DeckModel(
      id: id ?? map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      subject: map['subject'] as String? ?? 'Other',
      accentColorHex: map['accentColorHex'] as String? ?? '#2D5A3D',
      cardCount: map['cardCount'] as int? ?? 0,
      dueCount: map['dueCount'] as int? ?? 0,
      masteryPercent: (map['masteryPercent'] as num?)?.toDouble() ?? 0.0,
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
      'userId': userId,
      'name': name,
      'description': description,
      'subject': subject,
      'accentColorHex': accentColorHex,
      'cardCount': cardCount,
      'dueCount': dueCount,
      'masteryPercent': masteryPercent,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  DeckModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? subject,
    String? accentColorHex,
    int? cardCount,
    int? dueCount,
    double? masteryPercent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeckModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      cardCount: cardCount ?? this.cardCount,
      dueCount: dueCount ?? this.dueCount,
      masteryPercent: masteryPercent ?? this.masteryPercent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
