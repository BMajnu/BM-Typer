import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bm_typer/presentation/screens/tutor_screen.dart';
import 'package:bm_typer/core/services/database_service.dart';
import 'package:bm_typer/core/services/migration_service.dart';
import 'package:bm_typer/core/services/reminder_service.dart';
import 'package:bm_typer/core/services/leaderboard_service.dart';
import 'package:bm_typer/core/models/leaderboard_entry_model.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
import 'package:bm_typer/core/providers/theme_provider.dart';
import 'package:bm_typer/core/providers/language_provider.dart';
import 'package:bm_typer/presentation/screens/user_registration_screen.dart';
import 'package:bm_typer/core/models/user_model.dart';
import 'package:bm_typer/core/models/typing_session.dart';
import 'package:bm_typer/core/services/sound_service.dart';
import 'package:bm_typer/core/services/tts_service.dart';
import 'package:bm_typer/core/services/accessibility_service.dart';
import 'package:bm_typer/presentation/screens/typing_speed_test_screen.dart';
import 'package:bm_typer/presentation/screens/typing_test_results_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DatabaseService.initialize();

  // Register Hive adapters
  Hive.registerAdapter(LeaderboardEntryAdapter());
  Hive.registerAdapter(TypingSessionAdapter());

  // Check for and run migrations if needed
  await MigrationService.checkAndMigrateIfNeeded();
  await MigrationService.migrateDatabaseFormats();

  // Initialize the leaderboard service
  await LeaderboardService.initialize();

  // Initialize services
  final soundService = SoundService();
  await soundService.initialize();

  final ttsService = TtsService();
  await ttsService.initialize();

  final accessibilityService = AccessibilityService();
  await accessibilityService.initialize();

  runApp(
    const ProviderScope(
      child: BMTyperApp(),
    ),
  );
}

class BMTyperApp extends ConsumerWidget {
  const BMTyperApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final themeState = ref.watch(themeProvider);
    final appLanguage = ref.watch(appLanguageProvider);

    // Get platform brightness for system theme mode
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final brightness = themeState.getBrightness(platformBrightness);

    // App title based on language
    final appTitle = appLanguage == AppLanguage.bengali
        ? 'বিএম টাইপার - ইন্টারেক্টিভ বাংলা টাইপিং টিউটর'
        : 'BM Typer - Interactive Bangla Typing Tutor';

    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: themeState.getLightTheme(),
      darkTheme: themeState.getDarkTheme(),
      themeMode: themeState.themeMode,
      home: currentUser == null
          ? const UserRegistrationScreen()
          : const TutorScreen(),
      routes: {
        '/typing_test': (context) => const TypingSpeedTestScreen(),
        '/typing_test_results': (context) => const TypingTestResultsScreen(),
      },
    );
  }
}
