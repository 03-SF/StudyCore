import 'package:cloud_firestore/cloud_firestore.dart';
import 'achievement_model.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? bio;
  final List<String> subjects;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastStudiedAt;
  final List<Achievement> achievements;
  final int totalCardsStudied;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.bio,
    required this.subjects,
    required this.createdAt,
    required this.updatedAt,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastStudiedAt,
    this.achievements = const [],
    this.totalCardsStudied = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      bio: map['bio'] as String?,
      subjects: List<String>.from(map['subjects'] as List? ?? []),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      currentStreak: map['currentStreak'] as int? ?? 0,
      longestStreak: map['longestStreak'] as int? ?? 0,
      lastStudiedAt: map['lastStudiedAt'] is Timestamp
          ? (map['lastStudiedAt'] as Timestamp).toDate()
          : null,
      achievements: (map['achievements'] as List? ?? [])
          .map((a) => Achievement.fromMap(a as Map<String, dynamic>))
          .toList(),
      totalCardsStudied: map['totalCardsStudied'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bio': bio,
      'subjects': subjects,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastStudiedAt':
          lastStudiedAt != null ? Timestamp.fromDate(lastStudiedAt!) : null,
      'achievements': achievements.map((a) => a.toMap()).toList(),
      'totalCardsStudied': totalCardsStudied,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    bool clearPhotoUrl = false,
    String? bio,
    List<String>? subjects,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastStudiedAt,
    List<Achievement>? achievements,
    int? totalCardsStudied,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
      bio: bio ?? this.bio,
      subjects: subjects ?? this.subjects,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
      achievements: achievements ?? this.achievements,
      totalCardsStudied: totalCardsStudied ?? this.totalCardsStudied,
    );
  }
}
