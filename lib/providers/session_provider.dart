import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../models/study_session_model.dart';
import '../services/srs_service.dart';
import '../services/card_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class SessionProvider extends ChangeNotifier {
  final SrsService _srsService = SrsService();
  final CardService _cardService = CardService();
  final _uuid = const Uuid();

  List<CardModel> _cards = [];
  int _currentIndex = 0;
  Map<String, int> _ratings = {};
  DateTime? _sessionStart;
  bool _isComplete = false;
  StudySessionModel? _lastSession;

  List<CardModel> get cards => _cards;
  int get currentIndex => _currentIndex;
  bool get isComplete => _isComplete;
  StudySessionModel? get lastSession => _lastSession;
  double get progress => _cards.isEmpty ? 0.0 : _currentIndex / _cards.length;

  CardModel? get currentCard =>
      _currentIndex < _cards.length ? _cards[_currentIndex] : null;

  void startSession(List<CardModel> cards) {
    _cards = List.from(cards)..shuffle();
    _currentIndex = 0;
    _ratings = {};
    _sessionStart = DateTime.now();
    _isComplete = false;
    _lastSession = null;
    notifyListeners();
  }

  void rateCard(int rating) {
    if (_currentIndex >= _cards.length) return;
    final card = _cards[_currentIndex];
    _ratings[card.id] = rating;
    _currentIndex++;
    if (_currentIndex >= _cards.length) {
      _isComplete = true;
    }
    notifyListeners();
  }

  Future<StudySessionModel?> finalizeSession({
    required String userId,
    required String deckId,
    required String deckName,
    required String sessionType,
  }) async {
    if (!_isComplete) return null;

    final updatedCards = <CardModel>[];
    for (final card in _cards) {
      final rating = _ratings[card.id] ?? 1;
      updatedCards.add(_srsService.processRating(card, rating));
    }

    try {
      await _cardService.batchUpdateCards(deckId, updatedCards);

      final correct = _ratings.values.where((r) => r >= 3).length;
      final wrong = _ratings.values.where((r) => r < 3).length;
      final duration = DateTime.now()
          .difference(_sessionStart ?? DateTime.now())
          .inSeconds;

      final sessionId = _uuid.v4();
      final session = StudySessionModel(
        id: sessionId,
        userId: userId,
        deckId: deckId,
        deckName: deckName,
        sessionType: sessionType,
        totalCards: _cards.length,
        correctCards: correct,
        wrongCards: wrong,
        durationSeconds: duration,
        startedAt: _sessionStart ?? DateTime.now(),
        completedAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('studySessions')
          .doc(sessionId)
          .set(session.toMap());

      _lastSession = session;
      notifyListeners();
      return session;
    } catch (e) {
      return null;
    }
  }

  List<CardModel> getWrongCards() {
    return _cards
        .where((card) => (_ratings[card.id] ?? 1) < 3)
        .toList();
  }

  void reset() {
    _cards = [];
    _currentIndex = 0;
    _ratings = {};
    _sessionStart = null;
    _isComplete = false;
    _lastSession = null;
    notifyListeners();
  }
}
