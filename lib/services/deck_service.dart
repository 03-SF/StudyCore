import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/deck_model.dart';

class DeckService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Stream<List<DeckModel>> decksStream(String userId) {
    return _firestore
        .collection('decks')
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeckModel.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  Future<DeckModel> createDeck({
    required String userId,
    required String name,
    required String description,
    required String subject,
    required String accentColorHex,
  }) async {
    final id = _uuid.v4();
    final deck = DeckModel(
      id: id,
      userId: userId,
      name: name,
      description: description,
      subject: subject,
      accentColorHex: accentColorHex,
      cardCount: 0,
      dueCount: 0,
      masteryPercent: 0.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore.collection('decks').doc(id).set(deck.toMap());
    return deck;
  }

  Future<void> updateDeck({
    required String deckId,
    required String name,
    required String description,
    required String subject,
    required String accentColorHex,
  }) async {
    await _firestore.collection('decks').doc(deckId).update({
      'name': name,
      'description': description,
      'subject': subject,
      'accentColorHex': accentColorHex,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteDeck(String deckId) async {
    final cardsSnapshot = await _firestore
        .collection('decks')
        .doc(deckId)
        .collection('cards')
        .get();

    final batch = _firestore.batch();
    for (final doc in cardsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection('decks').doc(deckId));
    await batch.commit();
  }

  Future<DeckModel?> getDeck(String deckId) async {
    final doc = await _firestore.collection('decks').doc(deckId).get();
    if (!doc.exists) return null;
    return DeckModel.fromMap(doc.data()!, id: doc.id);
  }

  Future<void> updateMastery(String deckId, double mastery) async {
    await _firestore.collection('decks').doc(deckId).update({
      'masteryPercent': mastery,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
