import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    if (kIsWeb) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);
    _setupFcmHandlers();
  }

  Future<void> requestPermission() async {
    if (kIsWeb) return;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  void _setupFcmHandlers() {
    if (kIsWeb) return;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(
        title: message.notification?.title ?? 'StudyCore',
        body: message.notification?.body ?? '',
      );
    });
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      'studycore_channel',
      'StudyCore Notifications',
      channelDescription: 'Notifications from StudyCore',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  Future<void> scheduleDailyReminder(int hour, int minute) async {
    if (kIsWeb) return;

    await _localNotifications.cancelAll();

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(AppConstants.prefKeyReminderEnabled) ?? false;
    if (!enabled) return;

    const androidDetails = AndroidNotificationDetails(
      'studycore_reminder',
      'Daily Study Reminder',
      channelDescription: 'Daily reminder to study',
      importance: Importance.defaultImportance,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.periodicallyShow(
      0,
      'Time to study!',
      'Keep your streak going with StudyCore.',
      RepeatInterval.daily,
      details,
    );
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _localNotifications.cancelAll();
  }
}
