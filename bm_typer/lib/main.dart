import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:bm_typer/presentation/screens/auth_screen.dart';
import 'package:bm_typer/core/models/user_model.dart';
import 'package:bm_typer/core/models/typing_session.dart';
import 'package:bm_typer/core/services/sound_service.dart';
import 'package:bm_typer/core/services/tts_service.dart';
import 'package:bm_typer/core/services/accessibility_service.dart';
import 'package:bm_typer/presentation/screens/typing_speed_test_screen.dart';
import 'package:bm_typer/presentation/screens/typing_test_results_screen.dart';
import 'package:bm_typer/presentation/screens/profile_screen.dart';
import 'package:bm_typer/presentation/screens/account_settings_screen.dart';
import 'package:bm_typer/presentation/screens/leaderboard_screen.dart';
import 'package:bm_typer/presentation/screens/subscription_screen.dart';
import 'package:bm_typer/presentation/screens/subscription_screen.dart';
import 'package:bm_typer/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:bm_typer/presentation/screens/team_lead/team_lead_dashboard_screen.dart';
import 'package:bm_typer/presentation/screens/org_admin/org_admin_dashboard_screen.dart';
import 'package:bm_typer/presentation/wrappers/role_based_home_wrapper.dart';
import 'package:bm_typer/core/utils/route_guard.dart';
import 'package:bm_typer/core/enums/user_role.dart';

import 'package:google_fonts/google_fonts.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Disable runtime font fetching - use only bundled fonts
  // This fixes the AssetManifest.json error on Windows desktop
  GoogleFonts.config.allowRuntimeFetching = false;

  // Set up a global error handler to catch Flutter errors that would crash the app
  FlutterError.onError = (FlutterErrorDetails details) {
    print('CRITICAL FLUTTER ERROR: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };

  print('--- APP STARTUP BEGIN ---');

  try {
    print('Initializing Firebase...');
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
    
    // Note: Do NOT clear Firestore persistence or disable it
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  try {
    print('Initializing Database (Hive)...');
    // Initialize database
    await DatabaseService.initialize();
    print('DatabaseService initialized.');

    // Register Hive adapters
    Hive.registerAdapter(LeaderboardEntryAdapter());
    Hive.registerAdapter(TypingSessionAdapter());
    print('Hive adapters registered.');

    // Check for and run migrations if needed
    print('Checking migrations...');
    await MigrationService.checkAndMigrateIfNeeded();
    await MigrationService.migrateDatabaseFormats();
    print('Migrations completed.');

    // Initialize the leaderboard service
    print('Initializing LeaderboardService...');
    await LeaderboardService.initialize();
    print('LeaderboardService initialized.');
  } catch (e) {
    print('Database/Hive initialization failed: $e');
  }

  try {
    print('Initializing Connectivity/CloudSync...');
    // Initialize connectivity and cloud sync services
    await ConnectivityService().initialize();
    await CloudSyncService().initialize();
    print('Connectivity/CloudSync initialized.');
  } catch (e) {
    print('Connectivity services failed: $e');
  }

  try {
    print('Initializing Audio/TTS/Accessibility...');
    // Initialize services
    final soundService = SoundService();
    await soundService.initialize();

    final ttsService = TtsService();
    await ttsService.initialize();

    final accessibilityService = AccessibilityService();
    await accessibilityService.initialize();
    print('Audio/TTS/Accessibility initialized.');
  } catch (e) {
    print('Audio/TTS services failed: $e');
  }

  print('Calling runApp()...');
  runApp(
    const ProviderScope(
      child: BMTyperApp(),
    ),
  );
  print('runApp() called.');
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
        child: const RoleBasedHomeWrapper(),
      ),
      routes: {
        '/login': (context) => GlobalKeyboardShortcuts(child: const AuthScreen()),
        '/profile': (context) => GlobalKeyboardShortcuts(child: const ProfileScreen()),
        '/account_settings': (context) => GlobalKeyboardShortcuts(child: const AccountSettingsScreen()),
        '/leaderboard': (context) => GlobalKeyboardShortcuts(child: const LeaderboardScreen()),
        '/typing_test': (context) => GlobalKeyboardShortcuts(child: const TypingSpeedTestScreen()),
        '/typing_test_results': (context) => GlobalKeyboardShortcuts(child: const TypingTestResultsScreen()),
        '/subscription': (context) => GlobalKeyboardShortcuts(child: const SubscriptionScreen()),
        '/admin': (context) => GlobalKeyboardShortcuts(
          child: const RouteGuard(
            allowedRoles: [UserRole.superAdmin],
            child: AdminDashboardScreen(),
          ),
        ),
        '/team_lead': (context) => GlobalKeyboardShortcuts(
          child: const RouteGuard(
            allowedRoles: [UserRole.teamLead, UserRole.orgAdmin, UserRole.superAdmin],
            child: TeamLeadDashboardScreen(),
          ),
        ),
        '/org_admin': (context) => GlobalKeyboardShortcuts(
          child: const RouteGuard(
            allowedRoles: [UserRole.orgAdmin, UserRole.superAdmin],
            child: OrgAdminDashboardScreen(),
          ),
        ),
        '/practice': (context) => GlobalKeyboardShortcuts(child: const TutorScreen()),
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
