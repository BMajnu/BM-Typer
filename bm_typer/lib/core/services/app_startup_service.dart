import 'dart:async';

import 'package:bm_typer/core/models/leaderboard_entry_model.dart';
import 'package:bm_typer/core/models/typing_session.dart';
import 'package:bm_typer/core/services/accessibility_service.dart';
import 'package:bm_typer/core/services/cloud_sync_service.dart';
import 'package:bm_typer/core/services/connectivity_service.dart';
import 'package:bm_typer/core/services/database_service.dart';
import 'package:bm_typer/core/services/leaderboard_service.dart';
import 'package:bm_typer/core/services/migration_service.dart';
import 'package:bm_typer/core/services/reminder_service.dart';
import 'package:bm_typer/core/services/sound_service.dart';
import 'package:bm_typer/core/services/tts_service.dart';
import 'package:bm_typer/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppStartupService {
  AppStartupService._();

  static Future<void>? _criticalInitializationFuture;
  static Future<void>? _deferredInitializationFuture;

  static Future<void> initializeCritical() {
    return _criticalInitializationFuture ??= _initializeCriticalInternal();
  }

  static Future<void> initializeDeferred() {
    return _deferredInitializationFuture ??= _initializeDeferredInternal();
  }

  static Future<void> _initializeCriticalInternal() async {
    await _runStep(
      'Firebase',
      () => Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      timeout: const Duration(seconds: 12),
    );

    await _runStep(
      'Database',
      () async {
        _registerHiveAdapters();
        await DatabaseService.initialize();
        await MigrationService.checkAndMigrateIfNeeded();
        await MigrationService.migrateDatabaseFormats();
      },
      timeout: const Duration(seconds: 12),
    );
  }

  static Future<void> _initializeDeferredInternal() async {
    await initializeCritical();
    debugPrint('--- APP DEFERRED STARTUP BEGIN ---');

    await _runStep(
      'LeaderboardService',
      LeaderboardService.initialize,
      timeout: const Duration(seconds: 8),
    );

    await _runStep(
      'Connectivity/CloudSync',
      () async {
        await ConnectivityService().initialize();
        await CloudSyncService().initialize();
      },
      timeout: const Duration(seconds: 8),
    );

    await _runStep(
      'ReminderService',
      ReminderService.initialize,
      timeout: const Duration(seconds: 8),
    );

    await _runStep(
      'Audio/TTS/Accessibility',
      () async {
        final soundService = SoundService();
        await soundService.initialize();

        final ttsService = TtsService();
        await ttsService.initialize();

        final accessibilityService = AccessibilityService();
        await accessibilityService.initialize();
      },
      timeout: const Duration(seconds: 8),
    );

    debugPrint('--- APP DEFERRED STARTUP COMPLETE ---');
  }

  static void startDeferredInitialization() {
    unawaited(initializeDeferred());
  }

  static void _registerHiveAdapters() {
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(LeaderboardEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(TypingSessionAdapter());
    }
  }

  static Future<void> _runStep(
    String name,
    Future<void> Function() action, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      debugPrint('Initializing $name...');
      await action().timeout(timeout);
      debugPrint('$name initialized.');
    } catch (error, stackTrace) {
      debugPrint('$name failed: $error');
      debugPrint(stackTrace.toString());
    }
  }
}
