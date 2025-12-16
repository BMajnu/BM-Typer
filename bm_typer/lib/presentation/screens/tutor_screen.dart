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
import 'package:bm_typer/core/constants/keyboard_layouts.dart';
import 'package:bm_typer/core/models/achievement_model.dart';
import 'package:bm_typer/core/models/lesson_model.dart';

import 'package:bm_typer/core/services/notification_service.dart';
import 'package:bm_typer/core/services/reminder_service.dart';
import 'package:bm_typer/core/services/leaderboard_service.dart';
import 'package:bm_typer/data/local_lesson_data.dart';
import 'package:bm_typer/presentation/screens/profile_screen.dart';

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

import 'package:bm_typer/presentation/widgets/settings_panel.dart';
import 'package:bm_typer/presentation/utils/responsive_helper.dart';

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
  
  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);

    // Record that the user has practiced today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordPracticeSession();
      _checkForPendingAchievements();
      _initLeaderboard();
    });
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
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    ref.read(tutorProvider.notifier).setFocus(_focusNode.hasFocus);
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
                     child: Text("BM Typer", style: GoogleFonts.hindSiliguri(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.primary)),
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
             // Notification Button (for future Firebase integration)
             _buildHeaderButton(
               icon: Icons.notifications_outlined,
               onPressed: () {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text('শীঘ্রই আসছে! নোটিফিকেশন ফিচার Firebase এর সাথে ইন্টিগ্রেট করা হবে।', style: GoogleFonts.hindSiliguri()),
                     behavior: SnackBarBehavior.floating,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   ),
                 );
               },
               colorScheme: colorScheme,
               isDark: isDark,
               badge: true,
             ),
             const SizedBox(width: 8),
             // Settings Button
             _buildHeaderButton(
               icon: Icons.settings_rounded,
               onPressed: () => showSettingsPanel(context),
               colorScheme: colorScheme,
               isDark: isDark,
             ),
             const SizedBox(width: 8),
             // Profile Button
             _buildHeaderButton(
               icon: Icons.person_rounded,
               onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
               colorScheme: colorScheme,
               isDark: isDark,
               isPrimary: true,
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

class _LessonPickerSheet extends StatefulWidget {
  final ColorScheme colorScheme;
  final Function(int) onLessonSelected;
  final int currentLessonIndex;

  const _LessonPickerSheet({
    required this.colorScheme,
    required this.onLessonSelected,
    required this.currentLessonIndex,
  });

  @override
  State<_LessonPickerSheet> createState() => _LessonPickerSheetState();
}

class _LessonPickerSheetState extends State<_LessonPickerSheet> {
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
                    
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? widget.colorScheme.primaryContainer.withOpacity(0.3) : null,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: widget.colorScheme.primary, width: 2) : null,
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: isSelected ? widget.colorScheme.primary : widget.colorScheme.primaryContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text("${actualIndex + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : widget.colorScheme.primary, fontSize: 14)),
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
                          ],
                        ),
                        trailing: isSelected ? Icon(Icons.check_circle, color: widget.colorScheme.primary, size: 20) : null,
                        onTap: () => widget.onLessonSelected(actualIndex),
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
