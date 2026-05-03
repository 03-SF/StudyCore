import '../models/card_model.dart';

class SrsService {
  CardModel processRating(CardModel card, int rating) {
    int repetitions = card.repetitions;
    double easeFactor = card.easeFactor;
    int interval = card.interval;

    if (rating >= 3) {
      if (repetitions == 0) {
        interval = 1;
      } else if (repetitions == 1) {
        interval = 6;
      } else {
        interval = (interval * easeFactor).round();
      }
      repetitions += 1;
    } else {
      repetitions = 0;
      interval = 1;
    }

    easeFactor += 0.1 - (5 - rating) * (0.08 + (5 - rating) * 0.02);
    if (easeFactor < 1.3) easeFactor = 1.3;

    return card.copyWith(
      repetitions: repetitions,
      easeFactor: easeFactor,
      interval: interval,
      dueDate: DateTime.now().add(Duration(days: interval)),
      lastRating: rating,
      updatedAt: DateTime.now(),
    );
  }

  bool isDue(CardModel card) => DateTime.now().isAfter(card.dueDate);

  double calculateMastery(List<CardModel> cards) {
    if (cards.isEmpty) return 0.0;
    return cards.where((c) => c.interval >= 7).length / cards.length;
  }

  List<CardModel> getDueCards(List<CardModel> cards) {
    return cards.where(isDue).toList();
  }
}
