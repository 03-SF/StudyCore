import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/card_model.dart';

class CardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Stream<List<CardModel>> cardsStream(String deckId) {
    return _firestore
        .collection('decks')
        .doc(deckId)
        .collection('cards')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CardModel.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  Future<List<CardModel>> getCards(String deckId) async {
    final snapshot = await _firestore
        .collection('decks')
        .doc(deckId)
        .collection('cards')
        .get();
    return snapshot.docs
        .map((doc) => CardModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<CardModel> createCard({
    required String deckId,
    required String front,
    required String back,
    double easeFactor = 2.5,
  }) async {
    final id = _uuid.v4();
    final card = CardModel(
      id: id,
      deckId: deckId,
      front: front,
      back: back,
      easeFactor: easeFactor,
      interval: 1,
      repetitions: 0,
      dueDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('decks').doc(deckId).collection('cards').doc(id),
      card.toMap(),
    );
    batch.update(
      _firestore.collection('decks').doc(deckId),
      {
        'cardCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      },
    );
    await batch.commit();
    return card;
  }

  Future<void> updateCard({
    required String deckId,
    required String cardId,
    required String front,
    required String back,
    double? easeFactor,
  }) async {
    final updates = <String, dynamic>{
      'front': front,
      'back': back,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
    if (easeFactor != null) updates['easeFactor'] = easeFactor;

    await _firestore
        .collection('decks')
        .doc(deckId)
        .collection('cards')
        .doc(cardId)
        .update(updates);
  }

  Future<void> deleteCard(String deckId, String cardId) async {
    final batch = _firestore.batch();
    batch.delete(
      _firestore
          .collection('decks')
          .doc(deckId)
          .collection('cards')
          .doc(cardId),
    );
    batch.update(
      _firestore.collection('decks').doc(deckId),
      {
        'cardCount': FieldValue.increment(-1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      },
    );
    await batch.commit();
  }

  Future<void> updateCardSrs(String deckId, CardModel card) async {
    await _firestore
        .collection('decks')
        .doc(deckId)
        .collection('cards')
        .doc(card.id)
        .update({
      'easeFactor': card.easeFactor,
      'interval': card.interval,
      'repetitions': card.repetitions,
      'dueDate': Timestamp.fromDate(card.dueDate),
      'lastRating': card.lastRating,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> batchUpdateCards(
      String deckId, List<CardModel> cards) async {
    final batch = _firestore.batch();
    for (final card in cards) {
      batch.update(
        _firestore
            .collection('decks')
            .doc(deckId)
            .collection('cards')
            .doc(card.id),
        card.toMap(),
      );
    }
    await batch.commit();
  }

  Future<void> batchCreateCards(
      String deckId, List<Map<String, String>> cardPairs) async {
    final batch = _firestore.batch();
    for (final pair in cardPairs) {
      final id = _uuid.v4();
      final card = CardModel(
        id: id,
        deckId: deckId,
        front: pair['front'] ?? '',
        back: pair['back'] ?? '',
        dueDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      batch.set(
        _firestore.collection('decks').doc(deckId).collection('cards').doc(id),
        card.toMap(),
      );
    }
    batch.update(
      _firestore.collection('decks').doc(deckId),
      {
        'cardCount': FieldValue.increment(cardPairs.length),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      },
    );
    await batch.commit();
  }
}
