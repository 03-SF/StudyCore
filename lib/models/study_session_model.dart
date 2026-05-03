import 'package:cloud_firestore/cloud_firestore.dart';

class StudySessionModel {
  final String id;
  final String userId;
  final String deckId;
  final String deckName;
  final String sessionType;
  final int totalCards;
  final int correctCards;
  final int wrongCards;
  final int durationSeconds;
  final DateTime startedAt;
  final DateTime completedAt;

  const StudySessionModel({
    required this.id,
    required this.userId,
    required this.deckId,
    required this.deckName,
    required this.sessionType,
    required this.totalCards,
    required this.correctCards,
    required this.wrongCards,
    required this.durationSeconds,
    required this.startedAt,
    required this.completedAt,
  });

  double get scorePercent =>
      totalCards > 0 ? correctCards / totalCards : 0.0;

  factory StudySessionModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return StudySessionModel(
      id: id ?? map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      deckId: map['deckId'] as String? ?? '',
      deckName: map['deckName'] as String? ?? '',
      sessionType: map['sessionType'] as String? ?? 'flashcard',
      totalCards: map['totalCards'] as int? ?? 0,
      correctCards: map['correctCards'] as int? ?? 0,
      wrongCards: map['wrongCards'] as int? ?? 0,
      durationSeconds: map['durationSeconds'] as int? ?? 0,
      startedAt: map['startedAt'] is Timestamp
          ? (map['startedAt'] as Timestamp).toDate()
          : DateTime.now(),
      completedAt: map['completedAt'] is Timestamp
          ? (map['completedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'deckId': deckId,
      'deckName': deckName,
      'sessionType': sessionType,
      'totalCards': totalCards,
      'correctCards': correctCards,
      'wrongCards': wrongCards,
      'durationSeconds': durationSeconds,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': Timestamp.fromDate(completedAt),
    };
  }

  StudySessionModel copyWith({
    String? id,
    String? userId,
    String? deckId,
    String? deckName,
    String? sessionType,
    int? totalCards,
    int? correctCards,
    int? wrongCards,
    int? durationSeconds,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return StudySessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deckId: deckId ?? this.deckId,
      deckName: deckName ?? this.deckName,
      sessionType: sessionType ?? this.sessionType,
      totalCards: totalCards ?? this.totalCards,
      correctCards: correctCards ?? this.correctCards,
      wrongCards: wrongCards ?? this.wrongCards,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
