class AppConstants {
  AppConstants._();

  static const String appName = 'StudyCore';
  static const String appTagline = 'Master anything, one card at a time.';

  static const int defaultDailyGoal = 20;
  static const int minCardCount = 3;
  static const int maxCardCount = 20;
  static const int maxDeckNameLength = 80;
  static const int maxDescriptionLength = 200;
  static const int maxTextAreaLength = 3000;

  static const List<String> subjects = [
    'Mathematics',
    'Science',
    'History',
    'Literature',
    'Languages',
    'Computer Science',
    'Economics',
    'Psychology',
    'Medicine',
    'Law',
    'Philosophy',
    'Art',
    'Music',
    'Engineering',
    'Business',
    'Other',
  ];

  static const List<String> accentColors = [
    '#2D5A3D',
    '#4A7C59',
    '#C87533',
    '#B91C1C',
    '#1D4ED8',
    '#7C3AED',
    '#BE185D',
    '#0F766E',
  ];

  static const String prefKeyUserId = 'user_uid';
  static const String prefKeyDailyGoal = 'daily_goal';
  static const String prefKeyReminderEnabled = 'reminder_enabled';
  static const String prefKeyReminderTime = 'reminder_time';
  static const String prefKeyGroupMessages = 'group_messages';
  static const String prefKeyAiHints = 'ai_hints';
  static const String prefKeyThemeMode = 'theme_mode';
  static const String prefKeyQuizMode = 'quiz_mode';
}
