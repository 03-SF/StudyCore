import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/achievement_model.dart';

class StreakService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Records a study session and updates streak + achievements
  Future<void> recordStudySession(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return;

      final user = UserModel.fromMap(doc.data()!);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastStudied = user.lastStudiedAt;

      int newStreak = user.currentStreak;
      int newLongestStreak = user.longestStreak;
      DateTime? newLastStudied = lastStudied;

      // Check if this is a new day
      if (lastStudied == null) {
        newStreak = 1;
        newLastStudied = now;
      } else {
        final lastStudiedDay = DateTime(lastStudied.year, lastStudied.month, lastStudied.day);
        final yesterdayStart = DateTime(today.year, today.month, today.day - 1);

        if (lastStudiedDay == today) {
          // Already studied today
          return;
        } else if (lastStudiedDay == yesterdayStart) {
          // Continued streak
          newStreak = user.currentStreak + 1;
          newLastStudied = now;
        } else {
          // Streak broken, restart
          newStreak = 1;
          newLastStudied = now;
        }
      }

      newLongestStreak = newStreak > newLongestStreak ? newStreak : newLongestStreak;

      // Check for achievement unlocks
      final newAchievements = List<Achievement>.from(user.achievements);
      _unlockStreakAchievements(newStreak, newAchievements, now);
      _unlockCardsAchievements(user, newAchievements, now);

      await _firestore.collection('users').doc(userId).update({
        'lastStudiedAt': Timestamp.fromDate(newLastStudied),
        'currentStreak': newStreak,
        'longestStreak': newLongestStreak,
        'achievements': newAchievements.map((a) => a.toMap()).toList(),
      });
    } catch (_) {}
  }

  void _unlockStreakAchievements(int streak, List<Achievement> achievements, DateTime now) {
    const streakMilestones = [3, 7, 14, 30, 100];
    for (final milestone in streakMilestones) {
      if (streak == milestone && !achievements.any((a) => a.id == 'streak_$milestone')) {
        achievements.add(Achievement(
          id: 'streak_$milestone',
          title: '$milestone-Day Streak! 🔥',
          icon: '🔥',
          description: 'Studied for $milestone consecutive days',
          unlockedAt: now,
        ));
      }
    }
  }

  void _unlockCardsAchievements(UserModel user, List<Achievement> achievements, DateTime now) {
    // These would be calculated from total cards reviewed (stored separately or via aggregation)
    // For now, we just create the achievement structure
    // In production, you'd sum cards from all sessions
  }
}
