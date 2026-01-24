import 'dart:async';
import 'package:flutter/material.dart';

/// Service that handles scheduling and managing practice reminders (Web Stub)
class ReminderService {
  
  static Future<void> initialize() async {
    print('ReminderService initialized (Web mode - No notifications)');
  }

  static Future<bool> isReminderEnabled() async {
    return false;
  }

  static Future<TimeOfDay?> getReminderTime() async {
    return const TimeOfDay(hour: 20, minute: 0);
  }

  static Future<void> toggleReminders(bool enabled) async {
    // No-op
  }

  static Future<void> setReminderTime(TimeOfDay time) async {
    // No-op
  }

  static Future<void> recordPracticeSession() async {
    // We could save this to local storage if needed, but for now stub
  }

  static Future<bool> hasPracticedToday() async {
    return false;
  }

  static Future<void> scheduleReminder() async {
    // No-op
  }

  static Future<void> cancelReminder() async {
    // No-op
  }

  static Future<void> showTestNotification() async {
    print('Test notification requested (Web mode - No notifications)');
  }
}
