import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:shared_preferences/shared_preferences.dart';

/// Service that handles scheduling and managing practice reminders
class ReminderService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'practice_reminders';
  static const String _channelName = 'Practice Reminders';
  static const String _channelDescription =
      'Notifications to remind users to practice typing';

  static const String _reminderEnabledKey = 'reminder_enabled';
  static const String _reminderTimeKey = 'reminder_time';
  static const String _lastPracticeKey = 'last_practice_date';

  /// Initialize the notification service
  static Future<void> initialize() async {
    // Initialize timezone data
    tzdata.initializeTimeZones();

    // Initialize notification settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create the notification channel (Android only)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Schedule reminder if enabled
    final isEnabled = await isReminderEnabled();
    if (isEnabled) {
      await scheduleReminder();
    }
  }

  /// Handle when a notification is tapped
  static void _onNotificationTapped(NotificationResponse response) {
    // This will be called when a notification is tapped
    // We can navigate to the app or specific screen if needed
  }

  /// Check if reminders are enabled
  static Future<bool> isReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reminderEnabledKey) ?? false;
  }

  /// Get the scheduled reminder time
  static Future<TimeOfDay?> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_reminderTimeKey);

    if (timeString != null) {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        try {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          return TimeOfDay(hour: hour, minute: minute);
        } catch (e) {
          return null;
        }
      }
    }

    // Default reminder time (8:00 PM)
    return const TimeOfDay(hour: 20, minute: 0);
  }

  /// Enable or disable practice reminders
  static Future<void> toggleReminders(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderEnabledKey, enabled);

    if (enabled) {
      await scheduleReminder();
    } else {
      await cancelReminder();
    }
  }

  /// Set the time for daily practice reminders
  static Future<void> setReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reminderTimeKey, '${time.hour}:${time.minute}');

    final isEnabled = await isReminderEnabled();
    if (isEnabled) {
      await scheduleReminder();
    }
  }

  /// Record that the user has practiced today
  static Future<void> recordPracticeSession() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateString = '${now.year}-${now.month}-${now.day}';
    await prefs.setString(_lastPracticeKey, dateString);
  }

  /// Check if the user has practiced today
  static Future<bool> hasPracticedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPractice = prefs.getString(_lastPracticeKey);

    if (lastPractice == null) {
      return false;
    }

    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';

    return lastPractice == today;
  }

  /// Schedule a daily practice reminder
  static Future<void> scheduleReminder() async {
    // Cancel any existing reminder first
    await cancelReminder();

    // Get the reminder time
    final timeOfDay = await getReminderTime();
    if (timeOfDay == null) return;

    // Create a DateTime for the next occurrence of this time
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Schedule the notification
    await _notifications.zonedSchedule(
      0, // Notification ID
      'Time to Practice!', // Title
      'Maintain your streak by practicing typing today.', // Body
      scheduledDate, // Schedule time
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      // Schedule for daily occurrence
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancel scheduled reminders
  static Future<void> cancelReminder() async {
    await _notifications.cancel(0);
  }

  /// Show a test notification immediately
  static Future<void> showTestNotification() async {
    await _notifications.show(
      99, // Different ID for test notification
      'Practice Reminder Test',
      'This is a test practice reminder notification.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
