
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    _initialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {

  }

  Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? false;
  }


  Future<void> scheduleDailyReminder({
    int hour = 8,
    int minute = 0,
    String title = '🌸 Good morning, Hello!',
    String body =
        'Check today\'s AI scent picks based on your local weather.',
  }) async {
    await _plugin.periodicallyShow(
      0,
      title,
      body,
      RepeatInterval.daily,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Scent Reminder',
          channelDescription:
              'Daily reminder to check your AI fragrance picks',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFD4AF37),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }


  Future<void> showInstant({
    required String title,
    required String body,
    int id = 1,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'general',
          'General Notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFD4AF37),
        ),
      ),
    );
  }


  Future<void> showWeatherAlert({
    required double temperature,
    required String topPick,
  }) async {
    String emoji;
    String message;

    if (temperature >= 30) {
      emoji = '🔥';
      message =
          'Hot day ahead (${ temperature.toInt()}°C)! Your $topPick will shine in the heat.';
    } else if (temperature < 15) {
      emoji = '❄️';
      message =
          'Cold weather alert! Perfect conditions for your $topPick — rich notes will bloom.';
    } else {
      emoji = '✨';
      message =
          'Great fragrance weather today! Your $topPick is the AI top pick.';
    }

    await showInstant(
      title: '$emoji Today\'s Scent Alert',
      body: message,
      id: 2,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }
}
