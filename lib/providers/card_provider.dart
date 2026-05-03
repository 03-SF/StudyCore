import 'dart:async';
import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../services/card_service.dart';

class CardProvider extends ChangeNotifier {
  final CardService _cardService = CardService();

  List<CardModel> _cards = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<CardModel>>? _subscription;
  String? _currentDeckId;

  List<CardModel> get cards => _cards;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void startListening(String deckId) {
    if (_currentDeckId == deckId) return;
    _currentDeckId = deckId;
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _subscription = _cardService.cardsStream(deckId).listen(
      (cards) {
        _cards = cards;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Could not load cards. Check your connection.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _currentDeckId = null;
    _cards = [];
  }

  Future<bool> createCard({
    required String deckId,
    required String front,
    required String back,
    double easeFactor = 2.5,
  }) async {
    try {
      final card = await _cardService.createCard(
        deckId: deckId,
        front: front,
        back: back,
        easeFactor: easeFactor,
      );
      _cards.add(card);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Could not save. Check your connection.';
      return false;
    }
  }

  Future<bool> updateCard({
    required String deckId,
    required String cardId,
    required String front,
    required String back,
    double? easeFactor,
  }) async {
    try {
      await _cardService.updateCard(
        deckId: deckId,
        cardId: cardId,
        front: front,
        back: back,
        easeFactor: easeFactor,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Could not save. Check your connection.';
      return false;
    }
  }

  Future<bool> deleteCard(String deckId, String cardId) async {
    try {
      await _cardService.deleteCard(deckId, cardId);
      _cards.removeWhere((c) => c.id == cardId);
      notifyListeners();
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
