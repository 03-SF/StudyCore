import 'dart:async';
import 'package:flutter/material.dart';
import '../models/deck_model.dart';
import '../services/deck_service.dart';
import '../services/srs_service.dart';
import '../services/card_service.dart';

class DeckProvider extends ChangeNotifier {
  final DeckService _deckService = DeckService();
  final CardService _cardService = CardService();
  final SrsService _srsService = SrsService();

  List<DeckModel> _decks = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<DeckModel>>? _subscription;

  List<DeckModel> get decks => _decks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalDueCards =>
      _decks.fold(0, (sum, deck) => sum + deck.dueCount);

  List<DeckModel> search(String query) {
    if (query.isEmpty) return _decks;
    return _decks
        .where((d) =>
            d.name.toLowerCase().contains(query.toLowerCase()) ||
            d.subject.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void startListening(String userId) {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _subscription = _deckService.decksStream(userId).listen(
      (decks) {
        _decks = decks;
        _isLoading = false;
        notifyListeners();
        _refreshDueCounts(decks);
      },
      onError: (e) {
        _errorMessage = 'Could not load decks. Check your connection.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _decks = [];
  }

  Future<void> _refreshDueCounts(List<DeckModel> decks) async {
    for (final deck in decks) {
      try {
        final cards = await _cardService.getCards(deck.id);
        final due = _srsService.getDueCards(cards).length;
        final mastery = _srsService.calculateMastery(cards);
        if (due != deck.dueCount || (mastery - deck.masteryPercent).abs() > 0.01) {
          await _deckService.updateMastery(deck.id, mastery);
          final idx = _decks.indexWhere((d) => d.id == deck.id);
          if (idx != -1) {
            _decks[idx] = _decks[idx].copyWith(
              dueCount: due,
              masteryPercent: mastery,
            );
            notifyListeners();
          }
        }
      } catch (_) {}
    }
  }

  Future<DeckModel?> createDeck({
    required String userId,
    required String name,
    required String description,
    required String subject,
    required String accentColorHex,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final deck = await _deckService.createDeck(
        userId: userId,
        name: name,
        description: description,
        subject: subject,
        accentColorHex: accentColorHex,
      );
      return deck;
    } catch (e) {
      _errorMessage = 'Could not save. Check your connection.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateDeck({
    required String deckId,
    required String name,
    required String description,
    required String subject,
    required String accentColorHex,
  }) async {
    try {
      await _deckService.updateDeck(
        deckId: deckId,
        name: name,
        description: description,
        subject: subject,
        accentColorHex: accentColorHex,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Could not save. Check your connection.';
      return false;
    }
  }

  Future<bool> deleteDeck(String deckId) async {
    try {
      await _deckService.deleteDeck(deckId);
      return true;
    } catch (e) {
      _errorMessage = 'Could not delete. Check your connection.';
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
