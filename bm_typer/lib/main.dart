import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bm_typer/firebase_options.dart';
import 'package:bm_typer/presentation/screens/tutor_screen.dart';
import 'package:bm_typer/core/services/database_service.dart';
import 'package:bm_typer/core/services/migration_service.dart';
import 'package:bm_typer/core/services/reminder_service.dart';
import 'package:bm_typer/core/services/leaderboard_service.dart';
import 'package:bm_typer/core/services/connectivity_service.dart';
import 'package:bm_typer/core/services/cloud_sync_service.dart';
import 'package:bm_typer/core/models/leaderboard_entry_model.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
import 'package:bm_typer/core/providers/theme_provider.dart';
import 'package:bm_typer/core/providers/language_provider.dart';
import 'package:bm_typer/core/providers/keyboard_layout_provider.dart';
import 'package:bm_typer/core/constants/keyboard_layouts.dart';
import 'package:bm_typer/presentation/screens/user_registration_screen.dart';
import 'package:bm_typer/core/models/user_model.dart';
import 'package:bm_typer/core/models/typing_session.dart';
import 'package:bm_typer/core/services/sound_service.dart';
import 'package:bm_typer/core/services/tts_service.dart';
import 'package:bm_typer/core/services/accessibility_service.dart';
import 'package:bm_typer/presentation/screens/typing_speed_test_screen.dart';
import 'package:bm_typer/presentation/screens/typing_test_results_screen.dart';
import 'package:bm_typer/presentation/screens/profile_screen.dart';
import 'package:bm_typer/presentation/screens/leaderboard_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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

  // Initialize connectivity and cloud sync services
  await ConnectivityService().initialize();
  await CloudSyncService().initialize();

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
      home: GlobalKeyboardShortcuts(
        child: currentUser == null
            ? const UserRegistrationScreen()
            : const TutorScreen(),
      ),
      routes: {
        '/register': (context) => GlobalKeyboardShortcuts(child: const UserRegistrationScreen()),
        '/profile': (context) => GlobalKeyboardShortcuts(child: const ProfileScreen()),
        '/leaderboard': (context) => GlobalKeyboardShortcuts(child: const LeaderboardScreen()),
        '/typing_test': (context) => GlobalKeyboardShortcuts(child: const TypingSpeedTestScreen()),
        '/typing_test_results': (context) => GlobalKeyboardShortcuts(child: const TypingTestResultsScreen()),
      },
    );
  }
}

// ================================================================
// Global Keyboard Shortcuts Handler
// Handles Ctrl+Alt+V/A/E for layout switching globally
// ================================================================
class GlobalKeyboardShortcuts extends ConsumerStatefulWidget {
  final Widget child;

  const GlobalKeyboardShortcuts({super.key, required this.child});

  @override
  ConsumerState<GlobalKeyboardShortcuts> createState() => _GlobalKeyboardShortcutsState();
}

class _GlobalKeyboardShortcutsState extends ConsumerState<GlobalKeyboardShortcuts> {
  final FocusNode _focusNode = FocusNode();
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  KeyboardLayout? _previousLayout;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);
      
      // Check for keyboard shortcuts: Ctrl+Alt+V/A/E for layout switching
      final isCtrlPressed = _pressedKeys.contains(LogicalKeyboardKey.controlLeft) ||
                            _pressedKeys.contains(LogicalKeyboardKey.controlRight);
      final isAltPressed = _pressedKeys.contains(LogicalKeyboardKey.altLeft) ||
                           _pressedKeys.contains(LogicalKeyboardKey.altRight);
      
      if (isCtrlPressed && isAltPressed) {
        final currentLayout = ref.read(keyboardLayoutProvider).currentLayout;
        KeyboardLayout? targetLayout;
        
        // Ctrl+Alt+V = Bijoy
        if (event.logicalKey == LogicalKeyboardKey.keyV) {
          targetLayout = KeyboardLayout.bijoy;
        }
        // Ctrl+Alt+A = Avro/Phonetic
        else if (event.logicalKey == LogicalKeyboardKey.keyA) {
          targetLayout = KeyboardLayout.phonetic;
        }
        // Ctrl+Alt+E = English/QWERTY
        else if (event.logicalKey == LogicalKeyboardKey.keyE) {
          targetLayout = KeyboardLayout.qwerty;
        }
        
        if (targetLayout != null) {
          // If same layout is pressed again, revert to previous
          if (currentLayout == targetLayout && _previousLayout != null) {
            ref.read(keyboardLayoutProvider.notifier).setLayout(_previousLayout!);
            _previousLayout = currentLayout;
          } else {
            // Save current as previous and switch to target
            _previousLayout = currentLayout;
            ref.read(keyboardLayoutProvider.notifier).setLayout(targetLayout);
          }
        }
      }
      
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      autofocus: true,
      child: widget.child,
    );
  }
}
