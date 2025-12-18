import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bm_typer/core/constants/app_text_styles.dart';
import 'package:bm_typer/core/providers/tutor_provider.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
import 'package:bm_typer/core/providers/theme_provider.dart';
import 'package:bm_typer/core/providers/language_provider.dart';
import 'package:bm_typer/core/providers/keyboard_layout_provider.dart';
import 'package:bm_typer/core/providers/subscription_provider.dart';
import 'package:bm_typer/core/constants/keyboard_layouts.dart';
import 'package:bm_typer/core/models/achievement_model.dart';
import 'package:bm_typer/core/models/lesson_model.dart';
import 'package:bm_typer/core/models/subscription_model.dart';

import 'package:bm_typer/core/services/notification_service.dart';
import 'package:bm_typer/core/services/reminder_service.dart';
import 'package:bm_typer/core/services/leaderboard_service.dart';
import 'package:bm_typer/data/local_lesson_data.dart';
import 'package:bm_typer/core/services/auth_service.dart';
import 'package:bm_typer/presentation/screens/profile_screen.dart';
import 'package:bm_typer/presentation/widgets/notifications_panel.dart';
import 'package:bm_typer/core/services/notification_firestore_service.dart';

import 'package:bm_typer/presentation/screens/leaderboard_screen.dart';
import 'package:bm_typer/presentation/screens/level_details_screen.dart';

import 'package:bm_typer/presentation/widgets/lesson_navigation.dart';
import 'package:bm_typer/presentation/widgets/progress_indicator_widget.dart';
import 'package:bm_typer/presentation/widgets/stats_card.dart';
import 'package:bm_typer/presentation/widgets/typing_area.dart';
import 'package:bm_typer/presentation/widgets/typing_guide.dart';
import 'package:bm_typer/presentation/widgets/typing_session_history.dart';
import 'package:bm_typer/presentation/widgets/bangla_virtual_keyboard.dart';
import 'package:bm_typer/presentation/widgets/xp_gain_animation.dart';
import 'package:bm_typer/presentation/widgets/feature_lock_overlay.dart';

import 'package:bm_typer/presentation/widgets/settings_panel.dart';
import 'package:bm_typer/presentation/utils/responsive_helper.dart';
import 'package:bm_typer/core/services/feature_limit_service.dart';
import 'package:bm_typer/presentation/widgets/paywall_widget.dart' hide PremiumBadge;
import 'dart:async';


class TutorScreen extends ConsumerStatefulWidget {
  const TutorScreen({super.key});

  @override
  ConsumerState<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends ConsumerState<TutorScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FocusNode _focusNode = FocusNode();
  final Set<LogicalKeyboardKey> _logicalKeys = {};
  final Set<String> _pressedKeys = {}; // For string-based keys
  KeyboardLayout? _previousLayout; // Track previous layout for revert on double-press
  
  // Practice time tracking for feature limits
  Timer? _practiceTimer;
  int _sessionMinutes = 0;
  bool _limitReached = false;
  
  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);

    // Record that the user has practiced today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordPracticeSession();
      _checkForPendingAchievements();
      _initLeaderboard();
      _initSubscription();
      _startPracticeTimer();
    });
  }
  
  Future<void> _initSubscription() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      await ref.read(subscriptionStateProvider.notifier).initialize(user.id);
    }
  }

  Future<void> _initLeaderboard() async {
    await LeaderboardService.initialize();
  }

  Future<void> _recordPracticeSession() async {
    await ReminderService.recordPracticeSession();
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final updatedUser = user.updateLoginStreak();
      if (updatedUser != user) {
        await ref.read(currentUserProvider.notifier).updateUser(updatedUser);
      }
    }
  }

  void _checkForPendingAchievements() {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final previouslyUnlocked = user.unlockedAchievements;
    final allAchievements = Achievements.all;
    final achievementsToShow = allAchievements
        .where((achievement) =>
            previouslyUnlocked.contains(achievement.id) &&
            !user.shownAchievementNotifications.contains(achievement.id))
        .toList();

    if (achievementsToShow.isNotEmpty) {
      _showAchievementNotifications(achievementsToShow);
      final userNotifier = ref.read(currentUserProvider.notifier);
      for (final achievement in achievementsToShow) {
        userNotifier.markAchievementAsShown(achievement.id);
      }
    }
  }

  void _showAchievementNotifications(List<Achievement> achievements) {
    if (achievements.isEmpty) return;
    if (achievements.length == 1) {
      NotificationService.showAchievementNotification(
        context: context,
        achievement: achievements.first,
      );
    } else {
      NotificationService.showMultipleAchievements(
        context: context,
        achievements: achievements,
      );
    }
  }

  @override
  void dispose() {
    _practiceTimer?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  /// Start practice time tracking timer for feature limits
  void _startPracticeTimer() {
    final subscriptionState = ref.read(subscriptionStateProvider);
    
    // No timer needed for premium users
    if (subscriptionState.isPremium) return;
    
    _practiceTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final limitService = ref.read(featureLimitServiceProvider);
      final isPremium = ref.read(subscriptionStateProvider).isPremium;
      
      // Premium users don't need tracking
      if (isPremium) {
        timer.cancel();
        return;
      }
      
      // Record 1 minute of practice
      limitService.recordPracticeTime(1);
      _sessionMinutes++;
      
      // Check if limit reached
      final canContinue = limitService.canPractice(false);
      if (!canContinue.allowed && !_limitReached) {
        _limitReached = true;
        timer.cancel();
        
        // Show paywall dialog
        if (mounted) {
          showPaywallDialog(
            context,
            title: 'দৈনিক অনুশীলনের সময় শেষ!',
            message: 'আপনি আজ ${FeatureLimits.maxDailyPracticeMinutes} মিনিট অনুশীলন করেছেন। আনলিমিটেড অনুশীলনের জন্য প্রিমিয়াম নিন!',
            onUpgrade: () => Navigator.pushNamed(context, '/subscription'),
          );
        }
      }
      
      // Trigger UI rebuild to update banner
      if (mounted) setState(() {});
    });
  }

  void _onFocusChange() {
    ref.read(tutorProvider.notifier).setFocus(_focusNode.hasFocus);
  }
  
  /// Check if current user is admin
  bool _isAdminUser() {
    final user = ref.read(currentUserProvider);
    const adminEmails = [
      'badiuzzamanmajnu786@gmail.com',
    ];
    return adminEmails.contains(user?.email?.toLowerCase()) ||
           user?.email?.contains('admin') == true ||
           user?.customUserId?.toLowerCase() == 'admin';
  }


  /// Auto-switch to first lesson matching the new keyboard layout
  void _autoSwitchLessonForLayout(KeyboardLayout layout) {
    int? firstMatchingIndex;
    
    for (int i = 0; i < lessons.length; i++) {
      final lesson = lessons[i];
      bool matches = false;
      
      switch (layout) {
        case KeyboardLayout.qwerty:
          matches = lesson.language == 'en';
          break;
        case KeyboardLayout.bijoy:
          matches = lesson.language == 'bn' && lesson.category != 'Phonetic';
          break;
        case KeyboardLayout.phonetic:
          matches = lesson.category == 'Phonetic';
          break;
      }
      
      if (matches) {
        firstMatchingIndex = i;
        break;
      }
    }
    
    if (firstMatchingIndex != null) {
      ref.read(tutorProvider.notifier).selectLesson(firstMatchingIndex);
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      setState(() {
        _logicalKeys.add(event.logicalKey);
        _updatePressedKeysFromLogical(event.logicalKey, true);
      });
      
      // Check for keyboard shortcuts: Ctrl+Alt+V/A/E for layout switching
      final isCtrlPressed = _logicalKeys.contains(LogicalKeyboardKey.controlLeft) ||
                            _logicalKeys.contains(LogicalKeyboardKey.controlRight);
      final isAltPressed = _logicalKeys.contains(LogicalKeyboardKey.altLeft) ||
                           _logicalKeys.contains(LogicalKeyboardKey.altRight);
      
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
          return; // Don't process as typing input
        }
      }
      
    } else if (event is KeyUpEvent) {
      setState(() {
        _logicalKeys.remove(event.logicalKey);
        _updatePressedKeysFromLogical(event.logicalKey, false);
      });
    }
    ref.read(tutorProvider.notifier).handleKeyPress(event);
  }

  // Convert logical key to string representation for virtual keyboard
  void _updatePressedKeysFromLogical(LogicalKeyboardKey key, bool isPressed) {
    String? keyChar;
    if (key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) {
      keyChar = 'shift';
    } else if (key == LogicalKeyboardKey.backspace) {
      keyChar = '⌫';
    } else if (key == LogicalKeyboardKey.space) {
      keyChar = ' ';
    } else {
      final keyLabel = key.keyLabel.toLowerCase();
      if (keyLabel.length == 1) {
        keyChar = keyLabel;
      } else {
        switch (key) {
           case LogicalKeyboardKey.backquote: keyChar = '`'; break;
           case LogicalKeyboardKey.minus: keyChar = '-'; break;
           case LogicalKeyboardKey.equal: keyChar = '='; break;
           case LogicalKeyboardKey.bracketLeft: keyChar = '['; break;
           case LogicalKeyboardKey.bracketRight: keyChar = ']'; break;
           case LogicalKeyboardKey.backslash: keyChar = '\\'; break;
           case LogicalKeyboardKey.semicolon: keyChar = ';'; break;
           case LogicalKeyboardKey.quote: keyChar = '\''; break;
           case LogicalKeyboardKey.comma: keyChar = ','; break;
           case LogicalKeyboardKey.period: keyChar = '.'; break;
           case LogicalKeyboardKey.slash: keyChar = '/'; break;
           default: keyChar = null;
        }
      }
    }

    if (keyChar != null) {
      if (isPressed) {
        _pressedKeys.add(keyChar);
      } else {
        _pressedKeys.remove(keyChar);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Detect layout mode
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final colorScheme = Theme.of(context).colorScheme;

    // Listen for keyboard layout changes and auto-switch lessons
    ref.listen<KeyboardLayoutState>(keyboardLayoutProvider, (previous, next) {
      if (previous?.currentLayout != next.currentLayout) {
        _autoSwitchLessonForLayout(next.currentLayout);
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      // No default AppBar to save space
      drawer: !isDesktop
          ? Drawer(
              width: 300,
              child: Column(
                children: [
                   DrawerHeader(
                    decoration: BoxDecoration(color: colorScheme.primaryContainer),
                    child: Center(
                      child: Text('অনুশীলন তালিকা', style: GoogleFonts.hindSiliguri(fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Expanded(child: _buildExerciseList()),
                ],
              ),
            )
          : null,
      // floatingActionButton removed - functionality moved to settings panel
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.surface.withOpacity(0.8),
              colorScheme.surfaceVariant.withOpacity(0.5),
            ],
          ),
        ),
        child: SafeArea(
          child: KeyboardListener(
            focusNode: _focusNode,
            onKeyEvent: _handleKeyEvent,
            child: isDesktop
                ? _buildDesktopLayout(colorScheme)
                : _buildMobileLayout(colorScheme),
          ),
        ),
      ),
    );
  }

  // --- DESKTOP LAYOUT (3 Columns: Sidebar | Main | Hidden/Extra) ---
  Widget _buildDesktopLayout(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LEFT SIDEBAR (Sidebar + Stats + History + Exercises)
          // Moving all non-typing controls here to free up vertical space in center
          SizedBox(
            width: 320,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: colorScheme.surface.withOpacity(0.9),
              child: Column(
                children: [
                   Padding(
                     padding: const EdgeInsets.all(16.0),
                     child: Row(
                       children: [
                         Expanded(
                           child: Text("BM Typer", style: GoogleFonts.hindSiliguri(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                         ),
                         // Admin button for admin users
                         if (_isAdminUser())
                           IconButton(
                             icon: Icon(Icons.admin_panel_settings, color: Colors.deepPurple),
                             tooltip: 'অ্যাডমিন প্যানেল',
                             onPressed: () => Navigator.pushNamed(context, '/admin'),
                           ),
                       ],
                     ),
                   ),
                   Divider(height: 1),
                   
                   // --- LESSON SWITCHER ---
                   _buildLessonSwitcher(colorScheme),
                   Divider(height: 1),
                   
                   // --- STATS + REPETITION COUNTER ---
                   Padding(
                     padding: const EdgeInsets.all(12.0),
                     child: _buildEnhancedStats(colorScheme),
                   ),
                   Divider(height: 1),
                   
                   // --- EXERCISE LIST ---
                   Expanded(child: _buildExerciseList()),
                   Divider(height: 1),
                   
                   // --- PROGRESS / ENCOURAGEMENT MESSAGE ---
                   _buildProgressMessage(colorScheme),
                   
                   Divider(height: 1),
                   // History moved here (bottom of sidebar)
                   SizedBox(
                     height: 120,
                     child: _buildHistoryWidget(),
                   ),
                ],
              ),
            ),
          ),

          SizedBox(width: 16),

          // RIGHT MAIN AREA (Header + Typing + Keyboard)
          Expanded(
            child: Column(
              children: [
                // Slim Header (Breadcrumbs / Menu)
                _buildSlimHeader(colorScheme),
                
                // Practice Time Limit Banner (for free users only)
                _buildPracticeLimitBanner(colorScheme),
                
                // Typing Area - Flexible
                Expanded(
                  child: _buildTypingAreaAndGuide(isCompact: false),
                ),
                
                SizedBox(height: 12),

                // Keyboard - Fixed Height Container
                // This ensures keyboard always has adequate space and doesn't get crushed
                Container(
                  height: 260, // Fixed height for desktop
                  width: double.infinity,
                  padding: EdgeInsets.only(bottom: 8),
                  child: BanglaVirtualKeyboard(
                    pressedKeys: _pressedKeys,
                    showLayoutSwitcher: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- MOBILE LAYOUT ---
  Widget _buildMobileLayout(ColorScheme colorScheme) {
    final state = ref.watch(tutorProvider);
    final isUltraCompact = ResponsiveHelper.isUltraCompactHeight(context);

    return Column(
      children: [
        // Top Bar (Menu + Title) - Hide in UltraCompact
        if (!isUltraCompact)
          Container(
            height: 50,
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(icon: Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
                Text("BM Typer", style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold, fontSize: 18)),
                Spacer(),
                // Notification Bell
                const NotificationBell(size: 22),
                const SizedBox(width: 4),
                // Compact Stats Row for Mobile
                _buildCompactStatsRow(colorScheme),
              ],
            ),
          ),

        // Main Content (Typing + Guide)
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: _buildTypingAreaAndGuide(isCompact: true),
          ),
        ),

        // Keyboard at bottom
        Container(
          height: isUltraCompact ? 200 : 240, // Slightly smaller on mobile
          width: double.infinity,
          child: BanglaVirtualKeyboard(
            pressedKeys: _pressedKeys,
            showLayoutSwitcher: !isUltraCompact,
          ),
        ),
      ],
    );
  }

  // --- REFACTORED WIDGETS ---

  /// Build practice time limit banner for free users
  Widget _buildPracticeLimitBanner(ColorScheme colorScheme) {
    final subscriptionState = ref.watch(subscriptionStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Premium users - no banner
    if (subscriptionState.isPremium) {
      return const SizedBox.shrink();
    }
    
    final limitService = ref.watch(featureLimitServiceProvider);
    final remaining = limitService.getRemainingPracticeMinutes(false);
    final total = FeatureLimits.maxDailyPracticeMinutes;
    final used = total - remaining;
    final progress = used / total;
    
    // Determine colors based on remaining time
    Color bannerColor;
    Color textColor;
    IconData icon;
    
    if (remaining <= 0) {
      bannerColor = Colors.red.shade100;
      textColor = Colors.red.shade700;
      icon = Icons.block;
    } else if (remaining <= 3) {
      bannerColor = Colors.orange.shade100;
      textColor = Colors.orange.shade700;
      icon = Icons.warning_rounded;
    } else {
      bannerColor = Colors.blue.shade50;
      textColor = Colors.blue.shade700;
      icon = Icons.timer;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? bannerColor.withOpacity(0.15) : bannerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  remaining <= 0 
                      ? 'দৈনিক অনুশীলনের সময় শেষ!'
                      : 'বাকি আছে: $remaining মিনিট (মোট $total মিনিট)',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(textColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/subscription'),
            style: TextButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.workspace_premium, size: 16),
                const SizedBox(width: 6),
                Text('আপগ্রেড', style: GoogleFonts.hindSiliguri(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

   Widget _buildSlimHeader(ColorScheme colorScheme) {
     final isDark = Theme.of(context).brightness == Brightness.dark;
     return Container(
       height: 56,
       margin: EdgeInsets.only(bottom: 8),
       decoration: BoxDecoration(
         color: isDark ? colorScheme.surface.withOpacity(0.8) : colorScheme.surface,
         borderRadius: BorderRadius.circular(16),
         border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
         boxShadow: [
           BoxShadow(
             color: colorScheme.shadow.withOpacity(0.05),
             blurRadius: 10,
             offset: const Offset(0, 2),
           ),
         ],
       ),
       padding: EdgeInsets.symmetric(horizontal: 16),
       child: Row(
          children: [
             Container(
               padding: const EdgeInsets.all(8),
               decoration: BoxDecoration(
                 color: colorScheme.primary.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(10),
               ),
               child: Icon(Icons.keyboard_rounded, size: 20, color: colorScheme.primary),
             ),
             const SizedBox(width: 12),
             Text("Interactive Bangla Typing Tutor", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
             const Spacer(),
             // Notification Bell with real-time unread count
             _buildNotificationBell(colorScheme, isDark),
             const SizedBox(width: 8),
             // Settings Button
             _buildHeaderButton(
               icon: Icons.settings_rounded,
               onPressed: () => showSettingsPanel(context),
               colorScheme: colorScheme,
               isDark: isDark,
             ),
             const SizedBox(width: 8),
             // Profile Avatar Button
             _buildProfileAvatarButton(colorScheme, isDark),
             const SizedBox(width: 8),
             // Logout Button
             _buildHeaderButton(
               icon: Icons.logout_rounded,
               onPressed: () async {
                 // Show confirmation dialog
                 final shouldLogout = await showDialog<bool>(
                   context: context,
                   builder: (context) => AlertDialog(
                     title: Text('লগআউট', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
                     content: Text('আপনি কি নিশ্চিত যে আপনি লগআউট করতে চান?', style: GoogleFonts.hindSiliguri()),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                     actions: [
                       TextButton(
                         onPressed: () => Navigator.pop(context, false),
                         child: Text('না', style: GoogleFonts.hindSiliguri(color: Colors.grey)),
                       ),
                       TextButton(
                         onPressed: () => Navigator.pop(context, true),
                         child: Text('হ্যাঁ', style: GoogleFonts.hindSiliguri(color: Colors.red)),
                       ),
                     ],
                   ),
                 );

                 if (shouldLogout == true) {
                   await AuthService().signOut();
                   await ref.read(currentUserProvider.notifier).logout();
                 }
               },
               colorScheme: colorScheme,
               isDark: isDark,
             ),
          ],
       ),
     );
   }

   Widget _buildHeaderButton({
     required IconData icon,
     required VoidCallback onPressed,
     required ColorScheme colorScheme,
     required bool isDark,
     bool badge = false,
     bool isPrimary = false,
   }) {
     return Stack(
       children: [
         IconButton(
           onPressed: onPressed,
           icon: Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(
               color: isPrimary ? colorScheme.primary : (isDark ? Colors.white : Colors.black).withOpacity(0.08),
               borderRadius: BorderRadius.circular(10),
             ),
             child: Icon(
               icon,
               size: 20,
               color: isPrimary ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
             ),
           ),
         ),
         if (badge)
           Positioned(
             right: 8,
             top: 8,
             child: Container(
               width: 10,
               height: 10,
               decoration: BoxDecoration(
                 color: Colors.red,
                 shape: BoxShape.circle,
                 border: Border.all(color: isDark ? const Color(0xFF1a1a2e) : Colors.white, width: 2),
               ),
             ),
           ),
       ],
     );
  }

  Widget _buildNotificationBell(ColorScheme colorScheme, bool isDark) {
    final user = ref.watch(currentUserProvider);
    
    // If not logged in, show disabled bell
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.notifications_outlined,
          size: 20,
          color: (isDark ? Colors.white70 : Colors.black54).withOpacity(0.5),
        ),
      );
    }
    
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider(user.id));
    
    return GestureDetector(
      onTap: () => _showNotificationsPanel(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Badge(
          isLabelVisible: unreadCountAsync.when(
            data: (count) => count > 0,
            loading: () => false,
            error: (_, __) => false,
          ),
          label: unreadCountAsync.when(
            data: (count) => Text(
              count > 9 ? '9+' : '$count',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            loading: () => null,
            error: (_, __) => null,
          ),
          backgroundColor: Colors.red,
          child: Icon(
            Icons.notifications_outlined,
            size: 20,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ),
    );
  }
  
  void _showNotificationsPanel() {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 70, right: 16),
          child: Material(
            color: Colors.transparent,
            child: NotificationsPanel(
              onClose: () => Navigator.pop(ctx),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatarButton(ColorScheme colorScheme, bool isDark) {
    final user = ref.watch(currentUserProvider);
    final subscriptionState = ref.watch(subscriptionStateProvider);
    final isPremium = subscriptionState.isPremium;
    
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
      child: SizedBox(
        width: 46,
        height: 46,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ring (Premium golden ring or normal ring)
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isPremium 
                  ? LinearGradient(
                      colors: [
                        Colors.amber.shade300,
                        Colors.amber.shade600,
                        Colors.orange.shade500,
                        Colors.amber.shade400,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
                border: isPremium 
                  ? null 
                  : Border.all(color: colorScheme.primary, width: 2),
                boxShadow: isPremium 
                  ? [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ] 
                  : null,
              ),
            ),
            // Avatar
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primaryContainer,
              ),
              child: ClipOval(
                child: user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                    ? Image.network(
                        user.photoUrl!,
                        fit: BoxFit.cover,
                        width: 34,
                        height: 34,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
              ),
            ),
            // Premium Badge (if premium)
            if (isPremium)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? const Color(0xFF1a1a2e) : Colors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- MODERN LESSON SWITCHER ---
  Widget _buildLessonSwitcher(ColorScheme colorScheme) {
    final state = ref.watch(tutorProvider);
    final currentLesson = lessons[state.currentLessonIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.all(12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
              ? [colorScheme.primaryContainer.withOpacity(0.3), colorScheme.surface]
              : [colorScheme.primaryContainer.withOpacity(0.5), Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.school_rounded, size: 20, color: colorScheme.primary),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("বর্তমান লেসন", style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                    SizedBox(height: 2),
                    Text(
                      currentLesson.title,
                      style: GoogleFonts.hindSiliguri(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Lesson navigation buttons
          Row(
            children: [
              Expanded(
                child: _buildLessonNavButton(
                  icon: Icons.arrow_back_ios_rounded,
                  label: "আগের",
                  onTap: state.currentLessonIndex > 0
                      ? () => ref.read(tutorProvider.notifier).selectLesson(state.currentLessonIndex - 1)
                      : null,
                  colorScheme: colorScheme,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildLessonNavButton(
                  icon: Icons.list_alt_rounded,
                  label: "সব লেসন",
                  onTap: () => _showLessonPicker(context, colorScheme),
                  colorScheme: colorScheme,
                  isPrimary: true,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildLessonNavButton(
                  icon: Icons.arrow_forward_ios_rounded,
                  label: "পরের",
                  onTap: state.currentLessonIndex < lessons.length - 1
                      ? () => ref.read(tutorProvider.notifier).selectLesson(state.currentLessonIndex + 1)
                      : null,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLessonNavButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required ColorScheme colorScheme,
    bool isPrimary = false,
  }) {
    final isDisabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isDisabled 
              ? Colors.grey.withOpacity(0.1)
              : isPrimary 
                  ? colorScheme.primary.withOpacity(0.15)
                  : colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPrimary ? colorScheme.primary.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: isDisabled ? Colors.grey : colorScheme.primary),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: isDisabled ? Colors.grey : null, fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  void _showLessonPicker(BuildContext context, ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return _LessonPickerSheet(
          colorScheme: colorScheme,
          onLessonSelected: (index) {
            final lesson = lessons[index];
            // Auto-switch keyboard layout based on lesson type
            if (lesson.language == 'en') {
              ref.read(keyboardLayoutProvider.notifier).setLayout(KeyboardLayout.qwerty);
            } else if (lesson.category == 'Phonetic') {
              ref.read(keyboardLayoutProvider.notifier).setLayout(KeyboardLayout.phonetic);
            } else {
              ref.read(keyboardLayoutProvider.notifier).setLayout(KeyboardLayout.bijoy);
            }
            ref.read(tutorProvider.notifier).selectLesson(index);
            Navigator.pop(ctx);
          },
          currentLessonIndex: ref.watch(tutorProvider).currentLessonIndex,
        );
      },
    );
  }


  // --- ENHANCED STATS WITH REPS COUNTER ---
  Widget _buildEnhancedStats(ColorScheme colorScheme) {
    final state = ref.watch(tutorProvider);
    final hasReps = state.currentExercise.repetitions > 0;
    
    return Column(
      children: [
        _buildStatRow("WPM (গতি)", "${state.wpm}", Icons.speed, colorScheme.primary),
        SizedBox(height: 8),
        _buildStatRow("নির্ভুলতা", "${state.accuracy}%", Icons.check_circle, colorScheme.tertiary),
        SizedBox(height: 8),
        // Repetition Counter
        if (hasReps)
          _buildStatRow(
            "পুনরাবৃত্তি", 
            "${state.repsCompleted}/${state.currentExercise.repetitions}", 
            Icons.repeat, 
            colorScheme.secondary,
          ),
      ],
    );
  }

  // --- PROGRESS MESSAGE ---
  Widget _buildProgressMessage(ColorScheme colorScheme) {
    final state = ref.watch(tutorProvider);
    
    // Determine encouragement message based on performance
    String message;
    IconData icon;
    Color bgColor;
    
    if (state.accuracy >= 95 && state.wpm >= 30) {
      message = "অসাধারণ! আপনি দুর্দান্ত করছেন! 🌟";
      icon = Icons.star;
      bgColor = Colors.amber.withOpacity(0.2);
    } else if (state.accuracy >= 80) {
      message = "ভালো চলছে! চেষ্টা করতে থাকুন! 💪";
      icon = Icons.thumb_up;
      bgColor = Colors.green.withOpacity(0.2);
    } else if (state.charIndex > 0 && state.accuracy < 70) {
      message = "ধীরে চলুন, নির্ভুলতায় মনোযোগ দিন";
      icon = Icons.info_outline;
      bgColor = Colors.orange.withOpacity(0.2);
    } else {
      message = "টাইপিং শুরু করুন, আপনি পারবেন!";
      icon = Icons.keyboard;
      bgColor = colorScheme.primaryContainer.withOpacity(0.3);
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: bgColor,
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.hindSiliguri(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatsRow(ColorScheme colorScheme) {
    final state = ref.watch(tutorProvider);
     return Row(
       mainAxisSize: MainAxisSize.min,
       children: [
         Text("WPM: ${state.wpm}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
         SizedBox(width: 8),
         Text("Acc: ${state.accuracy}%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
         if (state.currentExercise.repetitions > 0) ...[
           SizedBox(width: 8),
           Text("${state.repsCompleted}/${state.currentExercise.repetitions}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
         ],
       ],
     );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        Spacer(),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTypingAreaAndGuide({required bool isCompact}) {
    final state = ref.watch(tutorProvider);
    final layoutState = ref.watch(keyboardLayoutProvider);
    final isBijoy = layoutState.isBengali && layoutState.currentLayout == KeyboardLayout.bijoy;
    final currentChar = state.getExpectedCharacter(isBijoy);
    final exerciseType = ref.watch(tutorProvider.notifier).currentExerciseType;
    final source = ref.watch(tutorProvider.notifier).currentExerciseSource;

    return Column(
       children: [
          // Typing Guide - Shows which finger to use
          if (state.isFocused && !state.waitingForNextRep)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
              child: TypingGuide(
                currentCharacter: currentChar,
                isVisible: true,
                isMobile: isCompact,
              ),
            ),
          
          // Waiting Message
          if (state.waitingForNextRep)
            Container(
              padding: EdgeInsets.all(8),
              margin: EdgeInsets.only(bottom: 8),
              color: Colors.amber.withOpacity(0.2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.space_bar, size: 16),
                  SizedBox(width: 8),
                  Text("Press Space to Continue", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),

          // Typing Area - Fills remaining space
          Expanded(
            child: TypingArea(
              text: state.exerciseText,
              currentIndex: state.charIndex,
              incorrectIndices: state.incorrectIndices,
              isFocused: state.isFocused,
              onTap: () {
                ref.read(tutorProvider.notifier).setFocus(true);
                _focusNode.requestFocus();
              },
              exerciseType: exerciseType,
              source: source,
              pendingPreBaseVowel: state.pendingPreBaseVowel,
            ),
          ),
       ],
    );
  }

  Widget _buildHistoryWidget() {
     final state = ref.watch(tutorProvider);
     return TypingSessionHistory(
        typedCharacters: state.sessionTypedCharacters,
        isDarkMode: Theme.of(context).brightness == Brightness.dark,
      );
  }

  Widget _buildExerciseList() {
    final state = ref.watch(tutorProvider);
    final currentLesson = lessons[state.currentLessonIndex];
    final exercises = currentLesson.exercises;
    final currentExerciseIndex = state.currentExerciseIndex;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.list_alt, size: 18, color: colorScheme.primary),
              SizedBox(width: 8),
              Text("এক্সারসাইজ", style: GoogleFonts.hindSiliguri(fontSize: 14, fontWeight: FontWeight.bold)),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${currentExerciseIndex + 1}/${exercises.length}",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
        // Exercise list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              final isSelected = index == currentExerciseIndex;
              final isCompleted = index < currentExerciseIndex;

              return Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () => ref.read(tutorProvider.notifier).selectExercise(index),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? colorScheme.primaryContainer.withOpacity(0.4)
                          : isCompleted
                              ? colorScheme.tertiary.withOpacity(0.1)
                              : colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? colorScheme.primary
                            : Colors.transparent,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Index/Status indicator
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? colorScheme.primary
                                : isCompleted 
                                    ? colorScheme.tertiary
                                    : colorScheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: isCompleted 
                              ? Icon(Icons.check, size: 16, color: Colors.white)
                              : Text(
                                  "${index + 1}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : colorScheme.primary,
                                  ),
                                ),
                        ),
                        SizedBox(width: 10),
                        // Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise.isParagraph ? "অনুচ্ছেদ ${index + 1}" : exercise.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.hindSiliguri(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? colorScheme.primary : null,
                                ),
                              ),
                              if (exercise.repetitions > 0)
                                Text(
                                  "${exercise.repetitions}x পুনরাবৃত্তি",
                                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                ),
                            ],
                          ),
                        ),
                        // Type icon
                        Icon(
                          exercise.isParagraph 
                              ? Icons.article
                              : exercise.type == ExerciseType.quote 
                                  ? Icons.format_quote
                                  : Icons.keyboard,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ================================================================
// Lesson Picker Sheet with Filter Tabs
// ================================================================
enum LessonFilter { all, qwerty, bijoy, phonetic }

class _LessonPickerSheet extends ConsumerStatefulWidget {
  final ColorScheme colorScheme;
  final Function(int) onLessonSelected;
  final int currentLessonIndex;

  const _LessonPickerSheet({
    required this.colorScheme,
    required this.onLessonSelected,
    required this.currentLessonIndex,
  });

  @override
  ConsumerState<_LessonPickerSheet> createState() => _LessonPickerSheetState();
}

class _LessonPickerSheetState extends ConsumerState<_LessonPickerSheet> {
  LessonFilter _currentFilter = LessonFilter.all;

  List<MapEntry<int, Lesson>> get filteredLessons {
    final allLessons = lessons.asMap().entries.toList();
    
    switch (_currentFilter) {
      case LessonFilter.all:
        return allLessons;
      case LessonFilter.qwerty:
        return allLessons.where((e) => e.value.language == 'en').toList();
      case LessonFilter.bijoy:
        return allLessons.where((e) => e.value.language == 'bn' && e.value.category != 'Phonetic').toList();
      case LessonFilter.phonetic:
        return allLessons.where((e) => e.value.category == 'Phonetic').toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
              ),
              SizedBox(height: 12),
              
              // Title
              Text("লেসন নির্বাচন করুন", style: GoogleFonts.hindSiliguri(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              
              // Filter Tabs
              _buildFilterTabs(),
              SizedBox(height: 12),
              
              // Lesson count
              Text("${filteredLessons.length} টি লেসন", style: TextStyle(color: Colors.grey, fontSize: 12)),
              SizedBox(height: 8),
              
              // Lesson List
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: filteredLessons.length,
                  itemBuilder: (context, index) {
                    final entry = filteredLessons[index];
                    final actualIndex = entry.key;
                    final lesson = entry.value;
                    final isSelected = actualIndex == widget.currentLessonIndex;
                    
                    // Check if lesson is locked for free users
                    final subscriptionState = ref.watch(subscriptionStateProvider);
                    final isLocked = !subscriptionState.isLessonAccessible(actualIndex);
                    
                    // Determine category color
                    Color categoryColor;
                    String categoryLabel;
                    if (lesson.language == 'en') {
                      categoryColor = Colors.blue;
                      categoryLabel = 'QWERTY';
                    } else if (lesson.category == 'Phonetic') {
                      categoryColor = Colors.green;
                      categoryLabel = 'ফনেটিক';
                    } else {
                      categoryColor = Colors.orange;
                      categoryLabel = 'বিজয়';
                    }
                    
                    return Opacity(
                      opacity: isLocked ? 0.6 : 1.0,
                      child: Container(
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? widget.colorScheme.primaryContainer.withOpacity(0.3) : null,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected ? Border.all(color: widget.colorScheme.primary, width: 2) : null,
                        ),
                        child: ListTile(
                          leading: Stack(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: isLocked 
                                    ? Colors.grey.shade400
                                    : isSelected 
                                      ? widget.colorScheme.primary 
                                      : widget.colorScheme.primaryContainer.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: isLocked
                                  ? Icon(Icons.lock_rounded, color: Colors.white, size: 18)
                                  : Text("${actualIndex + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : widget.colorScheme.primary, fontSize: 14)),
                              ),
                              if (isLocked)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: PremiumBadge(fontSize: 8),
                                ),
                            ],
                          ),
                          title: Text(lesson.title, style: GoogleFonts.hindSiliguri(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                          subtitle: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: categoryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(categoryLabel, style: TextStyle(fontSize: 9, color: categoryColor, fontWeight: FontWeight.bold)),
                              ),
                              SizedBox(width: 6),
                              Text("${lesson.exercises.length} এক্সারসাইজ", style: TextStyle(fontSize: 10, color: Colors.grey)),
                              if (isLocked) ...[
                                SizedBox(width: 6),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('প্রিমিয়াম', style: TextStyle(fontSize: 8, color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                          trailing: isSelected 
                            ? Icon(Icons.check_circle, color: widget.colorScheme.primary, size: 20) 
                            : isLocked 
                              ? Icon(Icons.lock_outline_rounded, color: Colors.orange, size: 18)
                              : null,
                          onTap: () {
                            if (isLocked) {
                              // Show upgrade dialog
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Row(
                                    children: [
                                      Icon(Icons.lock_rounded, color: Colors.orange),
                                      SizedBox(width: 8),
                                      Text('প্রিমিয়াম লেসন', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  content: Text(
                                    'এই লেসনটি প্রিমিয়াম ইউজারদের জন্য। ফ্রি প্ল্যানে প্রথম ${FreeFeatureLimits.maxLessons}টি লেসন অ্যাক্সেসযোগ্য।',
                                    style: GoogleFonts.hindSiliguri(),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text('বাদ দিন'),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        Navigator.pushNamed(context, '/subscription');
                                      },
                                      icon: Icon(Icons.stars_rounded, size: 18),
                                      label: Text('প্রিমিয়ামে আপগ্রেড'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepPurple,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              widget.onLessonSelected(actualIndex);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(LessonFilter.all, 'সব দেখুন', Icons.view_list, Colors.purple),
          SizedBox(width: 8),
          _buildFilterChip(LessonFilter.qwerty, 'QWERTY', Icons.keyboard, Colors.blue),
          SizedBox(width: 8),
          _buildFilterChip(LessonFilter.bijoy, 'বিজয়', Icons.language, Colors.orange),
          SizedBox(width: 8),
          _buildFilterChip(LessonFilter.phonetic, 'ফনেটিক', Icons.text_fields, Colors.green),
        ],
      ),
    );
  }

  Widget _buildFilterChip(LessonFilter filter, String label, IconData icon, Color color) {
    final isSelected = _currentFilter == filter;
    
    return GestureDetector(
      onTap: () => setState(() => _currentFilter = filter),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : color),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
