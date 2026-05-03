import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:uuid/uuid.dart';
import '../models/group_model.dart';
import '../models/deck_model.dart';
import '../models/card_model.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Stream<List<GroupModel>> myGroupsStream(String userId) {
    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => GroupModel.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  Future<List<GroupModel>> getPublicGroups({String? subject}) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('groups')
        .where('isPublic', isEqualTo: true)
        .orderBy('memberCount', descending: true)
        .limit(20);
    if (subject != null && subject.isNotEmpty) {
      query = query.where('subject', isEqualTo: subject);
    }
    final snap = await query.get();
    return snap.docs
        .map((doc) => GroupModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<GroupModel> createGroup({
    required String adminId,
    required String name,
    required String description,
    required String subject,
    required bool isPublic,
    String? photoUrl,
  }) async {
    final id = _uuid.v4();
    final group = GroupModel(
      id: id,
      name: name,
      description: description,
      subject: subject,
      adminId: adminId,
      memberIds: [adminId],
      photoUrl: photoUrl,
      isPublic: isPublic,
      sharedDeckCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore.collection('groups').doc(id).set(group.toMap());

    try {
      await FirebaseMessaging.instance.subscribeToTopic('group_$id');
    } catch (_) {}

    return group;
  }

  Future<void> joinGroup(String groupId, String userId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
      'memberCount': FieldValue.increment(1),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    try {
      await FirebaseMessaging.instance.subscribeToTopic('group_$groupId');
    } catch (_) {}
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'memberCount': FieldValue.increment(-1),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic('group_$groupId');
    } catch (_) {}
  }

  Future<void> shareDeckWithGroup(
      String groupId, DeckModel deck, List<CardModel> cards) async {
    final batch = _firestore.batch();
    final deckRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('sharedDecks')
        .doc(deck.id);
    batch.set(deckRef, {
      ...deck.toMap(),
      'sharedAt': Timestamp.fromDate(DateTime.now()),
    });

    batch.update(_firestore.collection('groups').doc(groupId), {
      'sharedDeckCount': FieldValue.increment(1),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    await batch.commit();
  }

  Future<void> addSharedDeckToLibrary(
      String userId, String groupId, String deckId) async {
    final sharedDeckDoc = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('sharedDecks')
        .doc(deckId)
        .get();

    if (!sharedDeckDoc.exists) return;

    final newDeckId = _uuid.v4();
    final deckData = sharedDeckDoc.data()!;
    final newDeck = {
      ...deckData,
      'id': newDeckId,
      'userId': userId,
      'cardCount': 0,
      'dueCount': 0,
      'masteryPercent': 0.0,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    await _firestore.collection('decks').doc(newDeckId).set(newDeck);
  }

  Stream<List<Map<String, dynamic>>> sharedDecksStream(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('sharedDecks')
        .orderBy('sharedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }
}
