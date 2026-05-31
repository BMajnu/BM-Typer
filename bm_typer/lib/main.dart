import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/presentation/screens/tutor_screen.dart';
import 'package:bm_typer/core/services/app_startup_service.dart';
import 'package:bm_typer/core/providers/theme_provider.dart';
import 'package:bm_typer/core/providers/language_provider.dart';
import 'package:bm_typer/core/providers/keyboard_layout_provider.dart';
import 'package:bm_typer/core/constants/keyboard_layouts.dart';
import 'package:bm_typer/presentation/screens/auth_screen.dart';
import 'package:bm_typer/presentation/screens/typing_speed_test_screen.dart';
import 'package:bm_typer/presentation/screens/typing_test_results_screen.dart';
import 'package:bm_typer/presentation/screens/profile_screen.dart';
import 'package:bm_typer/presentation/screens/account_settings_screen.dart';
import 'package:bm_typer/presentation/screens/leaderboard_screen.dart';
import 'package:bm_typer/presentation/screens/subscription_screen.dart';
import 'package:bm_typer/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:bm_typer/presentation/screens/team_lead/team_lead_dashboard_screen.dart';
import 'package:bm_typer/presentation/screens/org_admin/org_admin_dashboard_screen.dart';
import 'package:bm_typer/presentation/wrappers/role_based_home_wrapper.dart';
import 'package:bm_typer/presentation/widgets/update_checker.dart';
import 'package:bm_typer/presentation/widgets/web_download_prompt.dart';
import 'package:bm_typer/core/utils/route_guard.dart';
import 'package:bm_typer/presentation/screens/debug_screen.dart';
import 'package:bm_typer/core/enums/user_role.dart';

import 'package:google_fonts/google_fonts.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Disable runtime font fetching - use only bundled fonts
  // This fixes the AssetManifest.json error on Windows desktop
  GoogleFonts.config.allowRuntimeFetching = kIsWeb;

  // Set up a global error handler to catch Flutter errors that would crash the app
  FlutterError.onError = (FlutterErrorDetails details) {
    print('CRITICAL FLUTTER ERROR: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEF4444)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFEF4444), size: 52),
                    const SizedBox(height: 12),
                    const Text(
                      'BM Typer UI Error',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      details.exceptionAsString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFFFCA5A5)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    print('UNCAUGHT PLATFORM ERROR: $error');
    print('Platform stack trace: $stack');
    return true;
  };

  await AppStartupService.initializeCritical();

  runApp(
    const ProviderScope(
      child: BMTyperApp(),
    ),
  );

  unawaited(AppStartupService.initializeDeferred());
}

class BMTyperApp extends ConsumerWidget {
  const BMTyperApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final appLanguage = ref.watch(appLanguageProvider);

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
      builder: (context, child) {
        return WebDownloadPrompt(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: UpdateChecker(
        child: GlobalKeyboardShortcuts(
          child: const RoleBasedHomeWrapper(),
        ),
      ),
      routes: {
        '/login': (context) =>
            GlobalKeyboardShortcuts(child: const AuthScreen()),
        '/profile': (context) =>
            GlobalKeyboardShortcuts(child: const ProfileScreen()),
        '/account_settings': (context) =>
            GlobalKeyboardShortcuts(child: const AccountSettingsScreen()),
        '/leaderboard': (context) =>
            GlobalKeyboardShortcuts(child: const LeaderboardScreen()),
        '/typing_test': (context) =>
            GlobalKeyboardShortcuts(child: const TypingSpeedTestScreen()),
        '/typing_test_results': (context) =>
            GlobalKeyboardShortcuts(child: const TypingTestResultsScreen()),
        '/subscription': (context) =>
            GlobalKeyboardShortcuts(child: const SubscriptionScreen()),
        '/admin': (context) => GlobalKeyboardShortcuts(
              child: const RouteGuard(
                allowedRoles: [UserRole.superAdmin],
                child: AdminDashboardScreen(),
              ),
            ),
        '/team_lead': (context) => GlobalKeyboardShortcuts(
              child: const RouteGuard(
                allowedRoles: [
                  UserRole.teamLead,
                  UserRole.orgAdmin,
                  UserRole.superAdmin
                ],
                child: TeamLeadDashboardScreen(),
              ),
            ),
        '/org_admin': (context) => GlobalKeyboardShortcuts(
              child: const RouteGuard(
                allowedRoles: [UserRole.orgAdmin, UserRole.superAdmin],
                child: OrgAdminDashboardScreen(),
              ),
            ),
        '/practice': (context) =>
            GlobalKeyboardShortcuts(child: const TutorScreen()),
        '/debug': (context) =>
            GlobalKeyboardShortcuts(child: const DebugScreen()),
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
  ConsumerState<GlobalKeyboardShortcuts> createState() =>
      _GlobalKeyboardShortcutsState();
}

class _GlobalKeyboardShortcutsState
    extends ConsumerState<GlobalKeyboardShortcuts> {
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
      final isCtrlPressed =
          _pressedKeys.contains(LogicalKeyboardKey.controlLeft) ||
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
            ref
                .read(keyboardLayoutProvider.notifier)
                .setLayout(_previousLayout!);
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
