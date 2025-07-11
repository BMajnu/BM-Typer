import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bm_typer/core/constants/app_colors.dart';
import 'package:bm_typer/core/constants/app_text_styles.dart';
import 'package:bm_typer/core/providers/tutor_provider.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
import 'package:bm_typer/core/providers/theme_provider.dart';
import 'package:bm_typer/core/providers/language_provider.dart';
import 'package:bm_typer/core/models/achievement_model.dart';
import 'package:bm_typer/core/models/user_model.dart';
import 'package:bm_typer/core/services/achievement_service.dart';
import 'package:bm_typer/core/services/notification_service.dart';
import 'package:bm_typer/core/services/reminder_service.dart';
import 'package:bm_typer/core/services/leaderboard_service.dart';
import 'package:bm_typer/data/local_lesson_data.dart';
import 'package:bm_typer/presentation/screens/profile_screen.dart';
import 'package:bm_typer/presentation/screens/achievements_screen.dart';
import 'package:bm_typer/presentation/screens/leaderboard_screen.dart';
import 'package:bm_typer/presentation/screens/level_details_screen.dart';
import 'package:bm_typer/presentation/screens/theme_settings_screen.dart';
import 'package:bm_typer/presentation/screens/audio_settings_screen.dart';
import 'package:bm_typer/presentation/screens/accessibility_settings_screen.dart';
import 'package:bm_typer/presentation/widgets/lesson_navigation.dart';
import 'package:bm_typer/presentation/widgets/progress_indicator_widget.dart';
import 'package:bm_typer/presentation/widgets/stats_card.dart';
import 'package:bm_typer/presentation/widgets/typing_area.dart';
import 'package:bm_typer/presentation/widgets/typing_guide.dart';
import 'package:bm_typer/presentation/widgets/typing_session_history.dart';
import 'package:bm_typer/presentation/widgets/virtual_keyboard.dart';
import 'package:bm_typer/presentation/widgets/xp_gain_animation.dart';
import 'package:bm_typer/presentation/widgets/xp_progress_bar.dart';
import 'package:bm_typer/presentation/screens/export_screen.dart';

class TutorScreen extends ConsumerStatefulWidget {
  const TutorScreen({super.key});

  @override
  ConsumerState<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends ConsumerState<TutorScreen> {
  final FocusNode _focusNode = FocusNode();
  final Set<LogicalKeyboardKey> _logicalKeys = {};
  final Set<String> _pressedKeys = {}; // For string-based keys
  String _selectedContentLanguage =
      'all'; // Always set to 'all' to show all content

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
    // Initialize leaderboard service
    await LeaderboardService.initialize();
  }

  Future<void> _recordPracticeSession() async {
    // Record practice session for streak counting
    await ReminderService.recordPracticeSession();

    // Also update the user's streak in their profile
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

    // Get previously unlocked achievements
    final previouslyUnlocked = user.unlockedAchievements;

    // Compare with all possible achievements to see if any need to be shown
    final allAchievements = Achievements.all;
    final achievementsToShow = allAchievements
        .where((achievement) =>
            previouslyUnlocked.contains(achievement.id) &&
            !user.shownAchievementNotifications.contains(achievement.id))
        .toList();

    if (achievementsToShow.isNotEmpty) {
      _showAchievementNotifications(achievementsToShow);

      // Mark these achievements as shown
      final userNotifier = ref.read(currentUserProvider.notifier);
      for (final achievement in achievementsToShow) {
        userNotifier.markAchievementAsShown(achievement.id);
      }
    }
  }

  void _showAchievementNotifications(List<Achievement> achievements) {
    if (achievements.isEmpty) return;

    // Show different UI based on number of achievements
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

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      setState(() {
        _logicalKeys.add(event.logicalKey);
        // Also update string-based keys for the virtual keyboard
        _updatePressedKeysFromLogical(event.logicalKey, true);
      });
    } else if (event is KeyUpEvent) {
      setState(() {
        _logicalKeys.remove(event.logicalKey);
        // Also update string-based keys for the virtual keyboard
        _updatePressedKeysFromLogical(event.logicalKey, false);
      });
    }
    ref.read(tutorProvider.notifier).handleKeyPress(event);
  }

  // Convert logical key to string representation for virtual keyboard
  void _updatePressedKeysFromLogical(LogicalKeyboardKey key, bool isPressed) {
    String? keyChar;

    // Handle special keys
    if (key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) {
      keyChar = 'shift';
    } else if (key == LogicalKeyboardKey.backspace) {
      keyChar = '⌫';
    } else if (key == LogicalKeyboardKey.space) {
      keyChar = ' ';
    } else {
      // Handle letter keys and other printable characters
      final keyLabel = key.keyLabel.toLowerCase();
      if (keyLabel.length == 1) {
        keyChar = keyLabel;
      } else {
        // For other keys, check common symbols
        switch (key) {
          case LogicalKeyboardKey.backquote:
            keyChar = '`';
            break;
          case LogicalKeyboardKey.minus:
            keyChar = '-';
            break;
          case LogicalKeyboardKey.equal:
            keyChar = '=';
            break;
          case LogicalKeyboardKey.bracketLeft:
            keyChar = '[';
            break;
          case LogicalKeyboardKey.bracketRight:
            keyChar = ']';
            break;
          case LogicalKeyboardKey.backslash:
            keyChar = '\\';
            break;
          case LogicalKeyboardKey.semicolon:
            keyChar = ';';
            break;
          case LogicalKeyboardKey.quote:
            keyChar = '\'';
            break;
          case LogicalKeyboardKey.comma:
            keyChar = ',';
            break;
          case LogicalKeyboardKey.period:
            keyChar = '.';
            break;
          case LogicalKeyboardKey.slash:
            keyChar = '/';
            break;
          default:
            keyChar = null;
        }
      }
    }

    // Update the set of string keys
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
    final tutorState = ref.watch(tutorProvider);
    final themeState = ref.watch(themeProvider);
    final isDarkMode =
        themeState.getBrightness(MediaQuery.platformBrightnessOf(context)) ==
            Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final showTypingGuide =
        true; // This could be a user preference in the future

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 70,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'বিএম টাইপার - ইন্টারেক্টিভ বাংলা টাইপিং টিউটর',
            style: GoogleFonts.hindSiliguri(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: colorScheme.primary,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle, color: colorScheme.primary),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const ProfileScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOutCubic;
                    var tween = Tween(begin: begin, end: end).chain(
                      CurveTween(curve: curve),
                    );
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                ),
              );
            },
            tooltip: 'Profile',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'theme_btn',
            mini: true,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThemeSettingsScreen(),
                ),
              );
            },
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            tooltip: 'Theme Settings',
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return RotationTransition(
                  turns: animation,
                  child: ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                );
              },
              child: Icon(
                isDarkMode ? Icons.dark_mode : Icons.light_mode,
                key: ValueKey<bool>(isDarkMode),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'audio_btn',
            mini: true,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AudioSettingsScreen(),
                ),
              );
            },
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            tooltip: 'Audio Settings',
            child: const Icon(Icons.volume_up),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'accessibility_btn',
            mini: true,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccessibilitySettingsScreen(),
                ),
              );
            },
            backgroundColor: colorScheme.tertiaryContainer,
            foregroundColor: colorScheme.onTertiaryContainer,
            tooltip: 'Accessibility Settings',
            child: const Icon(Icons.accessibility_new),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'language_btn',
            mini: true,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  final appLanguage = ref.watch(appLanguageProvider);
                  return AlertDialog(
                    title: Text(
                        ref.watch(translationProvider('select_language')),
                        style: TextStyle(color: colorScheme.onSurface)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Interface language selection only
                        ListTile(
                          title: const Text('বাংলা'),
                          onTap: () {
                            ref
                                .read(appLanguageProvider.notifier)
                                .changeLanguage(AppLanguage.bengali);
                            Navigator.pop(context);
                          },
                          selected: appLanguage == AppLanguage.bengali,
                          leading: Radio<AppLanguage>(
                            value: AppLanguage.bengali,
                            groupValue: appLanguage,
                            onChanged: (value) {
                              if (value != null) {
                                ref
                                    .read(appLanguageProvider.notifier)
                                    .changeLanguage(value);
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                        ListTile(
                          title: const Text('English'),
                          onTap: () {
                            ref
                                .read(appLanguageProvider.notifier)
                                .changeLanguage(AppLanguage.english);
                            Navigator.pop(context);
                          },
                          selected: appLanguage == AppLanguage.english,
                          leading: Radio<AppLanguage>(
                            value: AppLanguage.english,
                            groupValue: appLanguage,
                            onChanged: (value) {
                              if (value != null) {
                                ref
                                    .read(appLanguageProvider.notifier)
                                    .changeLanguage(value);
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            backgroundColor: colorScheme.secondaryContainer,
            foregroundColor: colorScheme.onSecondaryContainer,
            tooltip: ref.watch(translationProvider('select_language')),
            child: const Icon(Icons.language),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'achievements_btn',
            mini: true,
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const AchievementsScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOutCubic;
                    var tween = Tween(begin: begin, end: end).chain(
                      CurveTween(curve: curve),
                    );
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                ),
              );
            },
            backgroundColor: colorScheme.tertiaryContainer,
            foregroundColor: colorScheme.onTertiaryContainer,
            tooltip: 'Achievements',
            child: const Icon(Icons.emoji_events),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'export_btn',
            mini: true,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExportScreen(),
                ),
              );
            },
            backgroundColor: colorScheme.secondaryContainer,
            foregroundColor: colorScheme.onSecondaryContainer,
            tooltip: 'Export & Share',
            child: const Icon(Icons.ios_share),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'speedtest_btn',
            mini: true,
            onPressed: () {
              Navigator.pushNamed(context, '/typing_test');
            },
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            tooltip: 'Typing Speed Test',
            child: const Icon(Icons.speed),
          ),
          const SizedBox(height: 8),
        ],
      ),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  // Desktop/tablet layout (wide screen)
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 300,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: _buildExerciseList(),
                        ),
                        Expanded(
                          flex: 3,
                          child: _buildExerciseContent(),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Mobile layout (narrow screen)
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withOpacity(0.1),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: constraints.maxHeight * 0.22,
                            child: _buildExerciseList(),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: _buildExerciseContent(),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final platform = Theme.of(context).platform;
    final isDesktop = [
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.macOS
    ].contains(platform);
    final isMobile = !isDesktop && !kIsWeb;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 8.0 : 16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  'Interactive Bangla Typing Tutor',
                  style: isMobile
                      ? AppTextStyles.title.copyWith(fontSize: 24)
                      : AppTextStyles.title,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'ধাপে ধাপে টাইপিং শিখুন এবং আপনার দক্ষতা পরীক্ষা করুন',
                  style: isMobile
                      ? AppTextStyles.subtitle.copyWith(fontSize: 14)
                      : AppTextStyles.subtitle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, size: 32),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            tooltip: 'Your Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildLessonContent() {
    final state = ref.watch(tutorProvider);
    final currentLesson = state.currentLesson;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentLesson.title,
              style: AppTextStyles.lessonTitle,
            ),
            const SizedBox(height: 8),
            Text(
              currentLesson.description,
              style: AppTextStyles.lessonDescription,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildExerciseList(),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildExerciseContent(),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildExerciseList(),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          flex: 3,
                          child: _buildExerciseContent(),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseList() {
    final state = ref.watch(tutorProvider);
    final currentLesson = lessons[state.currentLessonIndex];
    final exercises = currentLesson.exercises;
    final currentExerciseIndex = state.currentExerciseIndex;

    // Always show all lessons (no filtering)
    final allLessons = lessons;
    final filteredLessons = allLessons;

    final platform = Theme.of(context).platform;
    final isDesktop = [
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.macOS
    ].contains(platform);
    final isMobile = !isDesktop && !kIsWeb;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  ref.watch(translationProvider('exercises')),
                  style: GoogleFonts.hindSiliguri(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Lesson selector dropdown
              if (filteredLessons.length > 1)
                DropdownButton<int>(
                  value: filteredLessons.contains(currentLesson)
                      ? filteredLessons.indexOf(currentLesson)
                      : 0,
                  icon: Icon(Icons.arrow_drop_down, color: colorScheme.primary),
                  underline: Container(height: 0),
                  isDense: true,
                  dropdownColor: colorScheme.surfaceVariant,
                  style: TextStyle(color: colorScheme.onSurface),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      final lesson = filteredLessons[newValue];
                      final lessonIndex = allLessons.indexOf(lesson);
                      ref
                          .read(tutorProvider.notifier)
                          .selectLesson(lessonIndex);
                    }
                  },
                  items: List.generate(filteredLessons.length, (index) {
                    final lesson = filteredLessons[index];
                    return DropdownMenuItem<int>(
                      value: index,
                      child: Text(
                        ref.watch(translationProvider(lesson.title)),
                        style: TextStyle(fontSize: 14),
                      ),
                    );
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Add lesson description
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              ref.watch(translationProvider(currentLesson.description)),
              style: GoogleFonts.hindSiliguri(
                fontSize: isMobile ? 13 : 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          Expanded(
            child: AnimatedList(
              key: GlobalKey<AnimatedListState>(),
              initialItemCount: exercises.length,
              itemBuilder: (context, index, animation) {
                final exercise = exercises[index];
                final isSelected = index == currentExerciseIndex;
                final isLocked =
                    state.isLocked && index != currentExerciseIndex;

                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primaryContainer
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: colorScheme.shadow.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: TextButton(
                        onPressed: isLocked
                            ? null
                            : () => ref
                                .read(tutorProvider.notifier)
                                .selectExercise(index),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: isMobile ? 12.0 : 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerLeft,
                          foregroundColor: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                          disabledForegroundColor:
                              colorScheme.onSurface.withOpacity(0.38),
                        ),
                        child: Row(
                          children: [
                            if (isSelected)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  Icons.play_arrow,
                                  size: 18,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                exercise.isParagraph
                                    ? '${exercise.text.substring(0, min(30, exercise.text.length))}...'
                                    : exercise.text,
                                style: GoogleFonts.robotoMono(
                                  fontSize: isMobile ? 13 : 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: isMobile ? 1 : 2,
                              ),
                            ),
                            if (isLocked) const Icon(Icons.lock, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseContent() {
    final state = ref.watch(tutorProvider);
    final exerciseType = ref.watch(tutorProvider.notifier).currentExerciseType;
    final source = ref.watch(tutorProvider.notifier).currentExerciseSource;
    final platform = Theme.of(context).platform;
    final isDesktop = [
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.macOS
    ].contains(platform);
    final isMobile = !isDesktop && !kIsWeb;
    final currentChar = state.charIndex < state.exerciseText.length
        ? state.exerciseText[state.charIndex]
        : '';
    final colorScheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;

    // Make keyboard height responsive to screen size
    // Use a percentage of screen height with minimum and maximum values
    final keyboardHeightPercentage = 0.18; // 18% of screen height
    final minKeyboardHeight = 100.0;
    final maxKeyboardHeight = 180.0;

    final keyboardHeight = (screenSize.height * keyboardHeightPercentage)
        .clamp(minKeyboardHeight, maxKeyboardHeight);

    return Column(
      children: [
        // Stats cards with improved design
        Container(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCompactStatCard(
                context: context,
                title: state.currentExercise.repetitions > 0
                    ? "শব্দ/মিনিট"
                    : "গতি",
                value: "${state.wpm}",
                icon: Icons.speed_rounded,
                color: colorScheme.primary,
              ),
              _buildCompactStatCard(
                context: context,
                title: "নির্ভুলতা",
                value: "${state.accuracy}%",
                icon: Icons.check_circle_outline_rounded,
                color: colorScheme.tertiary,
              ),
              if (state.currentExercise.repetitions > 0)
                _buildCompactStatCard(
                  context: context,
                  title: "পুনরাবৃত্তি",
                  value:
                      "${state.repsCompleted}/${state.currentExercise.repetitions}",
                  icon: Icons.repeat_rounded,
                  color: colorScheme.secondary,
                ),
            ],
          ),
        ),

        SizedBox(height: isMobile ? 12.0 : 16.0),

        // Typing Guide with animation
        if (state.isFocused && !state.waitingForNextRep)
          AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TypingGuide(
                currentCharacter: currentChar,
                isVisible: true,
                isMobile: isMobile,
              ),
            ),
          ),

        // Show "Press Space to continue" when waiting for next repetition
        if (state.waitingForNextRep)
          AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.secondary.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.space_bar,
                    size: 24,
                    color: colorScheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'পরবর্তী অনুশীলন শুরু করতে স্পেসবার টিপুন',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Enhanced typing area - make it more flexible
        Expanded(
          flex: 3, // Give the typing area more space
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
          ),
        ),

        // Session typing history section
        TypingSessionHistory(
          typedCharacters: state.sessionTypedCharacters,
          isDarkMode: Theme.of(context).brightness == Brightness.dark,
        ),

        SizedBox(height: isMobile ? 8.0 : 12.0),

        // Virtual keyboard with animation - responsive and flexible with screen size
        if (isDesktop || kIsWeb)
          Expanded(
            flex: 2, // Give the keyboard proportional space
            child: SizedBox(
              width: double.infinity,
              child: LayoutBuilder(builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: VirtualKeyboard(
                      pressedKeys: _pressedKeys,
                    ),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildCompactStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surface.withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 6),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseStats() {
    final state = ref.watch(tutorProvider);
    final showReps = state.currentExercise.repetitions > 0;
    final platform = Theme.of(context).platform;
    final isDesktop = [
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.macOS
    ].contains(platform);
    final isMobile = !isDesktop && !kIsWeb;

    return StatsDisplay(
      wpm: state.wpm,
      accuracy: state.accuracy,
      repsCompleted: state.repsCompleted,
      totalReps: state.currentExercise.repetitions,
      showReps: showReps,
    );
  }

  Widget _buildNavigation() {
    final state = ref.watch(tutorProvider);

    return LessonNavigation(
      currentLessonIndex: state.currentLessonIndex,
      totalLessons: lessons.length,
      isPrevDisabled: state.currentLessonIndex == 0,
      isNextDisabled:
          state.isLocked || state.currentLessonIndex == lessons.length - 1,
      onPrevious: () => ref.read(tutorProvider.notifier).goToPreviousLesson(),
      onNext: () => ref.read(tutorProvider.notifier).goToNextLesson(),
    );
  }

  Widget _buildProgressIndicator() {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: LessonProgressIndicator(),
    );
  }

  void _handleExerciseComplete() {
    final tutorNotifier = ref.read(tutorProvider.notifier);
    final tutorState = ref.read(tutorProvider);
    final userNotifier = ref.read(currentUserProvider.notifier);
    final currentUser = ref.read(currentUserProvider);

    if (currentUser == null) return;

    // Get the exercise statistics
    final wpm = tutorState.wpm;
    final accuracy = tutorState.accuracy;
    final lessonTitle = tutorState.currentLesson.title;

    // Calculate XP gain based on performance
    int xpGained = _calculateXPGain(wpm.toDouble(), accuracy.toDouble());

    // Store the current level for comparison later
    final previousLevel = currentUser.level;

    // Add typing stats and check for new achievements
    userNotifier
        .addTypingStats(
      wpm: wpm.toDouble(),
      accuracy: accuracy.toDouble(),
      completedLesson: lessonTitle,
      additionalXp: xpGained,
    )
        .then((achievements) {
      // Show XP gain animation
      _showXPGainAnimation(xpGained);

      // Show achievements if any were unlocked
      _showAchievementNotifications(achievements);

      // Check for level up
      final newUser = ref.read(currentUserProvider);
      if (newUser != null && newUser.level > previousLevel) {
        _showLevelUpNotification(newUser.level);
      }

      // Record that the user has practiced today for streak tracking
      _recordPracticeSession();

      // Add entry to leaderboard if performance is good enough
      if (accuracy >= 85) {
        LeaderboardService.addEntry(
          user: newUser!,
          wpm: wpm.toDouble(),
          accuracy: accuracy.toDouble(),
          lessonId: lessonTitle,
        );
      }
    });

    // Show completion dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exercise Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('WPM: ${wpm.toStringAsFixed(1)}'),
            Text('Accuracy: ${(accuracy).toStringAsFixed(1)}%'),
            Text(
                'Time: ${_calculateTimeSeconds(tutorState).toStringAsFixed(1)} seconds'),
            const SizedBox(height: 8),
            Text(
              'XP Gained: +$xpGained',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LeaderboardScreen(),
                ),
              );
            },
            child: const Text('View Leaderboard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              tutorNotifier.selectExercise(tutorState.currentExerciseIndex + 1);
            },
            child: const Text('Next Exercise'),
          ),
        ],
      ),
    );
  }

  int _calculateXPGain(double wpm, double accuracy) {
    // Base XP for completing an exercise
    int xp = 3;

    // Bonus for good performance
    if (accuracy >= 98) {
      xp += 2; // Perfect accuracy bonus
    } else if (accuracy >= 95) {
      xp += 1; // High accuracy bonus
    }

    // Speed bonus
    if (wpm >= 80) {
      xp += 2; // Very fast typing
    } else if (wpm >= 50) {
      xp += 1; // Fast typing
    }

    return xp;
  }

  void _showXPGainAnimation(int xpAmount) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      XPGainOverlay.show(context, xpAmount);
    });
  }

  void _showLevelUpNotification(int newLevel) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Level Up!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_circle_up,
                color: Colors.amber,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                'Congratulations!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text('You reached level $newLevel!'),
              const SizedBox(height: 16),
              Text(
                'New rank: ${_getLevelTitle(newLevel)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Keep practicing to unlock more achievements and rise through the ranks!',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LevelDetailsScreen(),
                  ),
                );
              },
              child: const Text('View Level Details'),
            ),
          ],
        ),
      );
    });
  }

  String _getLevelTitle(int level) {
    if (level < 3) {
      return 'Beginner';
    } else if (level < 6) {
      return 'Apprentice';
    } else if (level < 10) {
      return 'Skilled Typist';
    } else if (level < 15) {
      return 'Expert Typist';
    } else if (level < 20) {
      return 'Master Typist';
    } else if (level < 30) {
      return 'Grandmaster';
    } else {
      return 'Legendary Typist';
    }
  }

  double _calculateTimeSeconds(TutorState state) {
    if (state.startTime == null) return 0;
    return DateTime.now().difference(state.startTime!).inMilliseconds / 1000;
  }
}
