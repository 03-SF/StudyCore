import 'package:cloud_firestore/cloud_firestore.dart';

class Achievement {
  final String id; // e.g., "streak_7", "cards_100"
  final String title;
  final String icon; // emoji or icon name
  final String description;
  final DateTime unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
    required this.unlockedAt,
  });

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      icon: map['icon'] as String? ?? '🏆',
      description: map['description'] as String? ?? '',
      unlockedAt: map['unlockedAt'] is Timestamp
          ? (map['unlockedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'icon': icon,
      'description': description,
      'unlockedAt': Timestamp.fromDate(unlockedAt),
    };
  }
}
