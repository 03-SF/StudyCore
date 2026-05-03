import 'package:cloud_firestore/cloud_firestore.dart';

class CardModel {
  final String id;
  final String deckId;
  final String front;
  final String back;
  final double easeFactor;
  final int interval;
  final int repetitions;
  final DateTime dueDate;
  final int lastRating;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CardModel({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    this.easeFactor = 2.5,
    this.interval = 1,
    this.repetitions = 0,
    required this.dueDate,
    this.lastRating = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CardModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return CardModel(
      id: id ?? map['id'] as String? ?? '',
      deckId: map['deckId'] as String? ?? '',
      front: map['front'] as String? ?? '',
      back: map['back'] as String? ?? '',
      easeFactor: (map['easeFactor'] as num?)?.toDouble() ?? 2.5,
      interval: map['interval'] as int? ?? 1,
      repetitions: map['repetitions'] as int? ?? 0,
      dueDate: map['dueDate'] is Timestamp
          ? (map['dueDate'] as Timestamp).toDate()
          : DateTime.now(),
      lastRating: map['lastRating'] as int? ?? 0,
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
      'deckId': deckId,
      'front': front,
      'back': back,
      'easeFactor': easeFactor,
      'interval': interval,
      'repetitions': repetitions,
      'dueDate': Timestamp.fromDate(dueDate),
      'lastRating': lastRating,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  CardModel copyWith({
    String? id,
    String? deckId,
    String? front,
    String? back,
    double? easeFactor,
    int? interval,
    int? repetitions,
    DateTime? dueDate,
    int? lastRating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CardModel(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      easeFactor: easeFactor ?? this.easeFactor,
      interval: interval ?? this.interval,
      repetitions: repetitions ?? this.repetitions,
      dueDate: dueDate ?? this.dueDate,
      lastRating: lastRating ?? this.lastRating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
