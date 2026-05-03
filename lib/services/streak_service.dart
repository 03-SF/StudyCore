import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/achievement_model.dart';

class StreakService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Records a study session and updates streak + achievements.
  /// [cardsStudied] is how many cards were answered in this session.
  Future<void> recordStudySession(String userId, {int cardsStudied = 0}) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return;

      final user = UserModel.fromMap(doc.data()!);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastStudied = user.lastStudiedAt;

      int newStreak = user.currentStreak;
      int newLongestStreak = user.longestStreak;
      DateTime newLastStudied = now;
      bool streakAlreadyCounted = false;

      if (lastStudied == null) {
        newStreak = 1;
      } else {
        final lastStudiedDay =
            DateTime(lastStudied.year, lastStudied.month, lastStudied.day);
        final yesterdayStart =
            DateTime(today.year, today.month, today.day - 1);

        if (lastStudiedDay == today) {
          // Already counted today's streak — only update cards
          newLastStudied = lastStudied;
          streakAlreadyCounted = true;
        } else if (lastStudiedDay == yesterdayStart) {
          newStreak = user.currentStreak + 1;
        } else {
          newStreak = 1;
        }
      }

      if (!streakAlreadyCounted) {
        newLongestStreak =
            newStreak > newLongestStreak ? newStreak : newLongestStreak;
      }

      final newTotal = user.totalCardsStudied + cardsStudied;

      final newAchievements = List<Achievement>.from(user.achievements);
      if (!streakAlreadyCounted) {
        _unlockStreakAchievements(newStreak, newAchievements, now);
      }
      _unlockCardAchievements(newTotal, newAchievements, now);

      await _firestore.collection('users').doc(userId).update({
        'lastStudiedAt': Timestamp.fromDate(newLastStudied),
        'currentStreak': newStreak,
        'longestStreak': newLongestStreak,
        'totalCardsStudied': newTotal,
        'achievements': newAchievements.map((a) => a.toMap()).toList(),
      });
    } catch (_) {}
  }

  void _unlockStreakAchievements(
      int streak, List<Achievement> achievements, DateTime now) {
    const milestones = [3, 7, 14, 30, 100];
    for (final m in milestones) {
      if (streak >= m && !achievements.any((a) => a.id == 'streak_$m')) {
        achievements.add(Achievement(
          id: 'streak_$m',
          title: '$m-Day Streak',
          icon: '🔥',
          description: 'Studied $m days in a row',
          unlockedAt: now,
        ));
      }
    }
  }

  void _unlockCardAchievements(
      int total, List<Achievement> achievements, DateTime now) {
    const milestones = {
      10: ('First Steps', '📖', 'Reviewed 10 cards'),
      50: ('On a Roll', '🚀', 'Reviewed 50 cards'),
      100: ('Century Club', '💯', 'Reviewed 100 cards'),
      500: ('Studious', '🎓', 'Reviewed 500 cards'),
      1000: ('Scholar', '🏆', 'Reviewed 1000 cards'),
    };
    milestones.forEach((count, data) {
      if (total >= count && !achievements.any((a) => a.id == 'cards_$count')) {
        achievements.add(Achievement(
          id: 'cards_$count',
          title: data.$1,
          icon: data.$2,
          description: data.$3,
          unlockedAt: now,
        ));
      }
    });
  }
}
