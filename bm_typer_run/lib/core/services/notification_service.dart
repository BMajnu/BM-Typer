import 'dart:math';
import 'package:flutter/material.dart';
import 'package:bm_typer/core/models/achievement_model.dart';
import 'package:bm_typer/core/services/achievement_service.dart';
import 'package:bm_typer/core/theme/theme.dart';
import 'package:bm_typer/presentation/widgets/achievement_badge.dart';

/// Service to show notifications for achievements and other events
class NotificationService {
  /// Show a popup notification for a new achievement
  static Future<void> showAchievementNotification({
    required BuildContext context,
    required Achievement achievement,
    VoidCallback? onDismiss,
  }) async {
    // Show overlay with achievement notification
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: _EnhancedAchievementUnlock(
          achievement: achievement,
          onComplete: () {
            Navigator.of(context).pop();
            if (onDismiss != null) {
              onDismiss();
            }
          },
        ),
      ),
    );
  }

  /// Show a toast notification for minor achievements or events
  static void showToastNotification({
    required BuildContext context,
    required String message,
    IconData icon = Icons.info,
    Color color = Colors.blue,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 50,
        left: 20,
        right: 20,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 220),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  /// Show an achievement panel with multiple achievements
  static Future<void> showMultipleAchievements({
    required BuildContext context,
    required List<Achievement> achievements,
    VoidCallback? onDismiss,
  }) async {
    if (achievements.isEmpty) return;

    final totalXp = achievements.fold<int>(
      0,
      (sum, achievement) => sum + achievement.xpReward,
    );

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;
        final mediaQuery = MediaQuery.of(context);
        final sheetHeightFactor = mediaQuery.size.height < 760 ? 0.88 : 0.78;

        return SafeArea(
          top: false,
          child: FractionallySizedBox(
            heightFactor: sheetHeightFactor,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surface,
                    colorScheme.surfaceContainerHighest.withValues(
                      alpha: isDark ? 89 : 140,
                    ),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.radiusXxl),
                ),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 89),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withValues(alpha: 242),
                          colorScheme.secondary.withValues(alpha: 217),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 71),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: colorScheme.onPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'নতুন অ্যাচিভমেন্ট আনলক হয়েছে',
                    textAlign: TextAlign.center,
                    style: AppTypography.banglaTitle(context).copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${achievements.length}টি ব্যাজ যুক্ত হয়েছে • মোট +$totalXp XP',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium(context).copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth >= 900
                            ? 4
                            : constraints.maxWidth >= 560
                                ? 3
                                : 2;
                        final badgeSize = constraints.maxWidth >= 560 ? 56.0 : 50.0;

                        return GridView.builder(
                          padding: const EdgeInsets.only(bottom: 8),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: constraints.maxHeight < 420 ? 1.08 : 0.96,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: achievements.length,
                          itemBuilder: (context, index) {
                            final achievement = achievements[index];
                            return _AchievementSheetCard(
                              achievement: achievement,
                              badgeSize: badgeSize,
                              showAnimation: index.isEven,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (onDismiss != null) {
                          onDismiss();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        ),
                      ),
                      child: Text(
                        'চালিয়ে যান',
                        style: AppTypography.labelLarge(context).copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AchievementSheetCard extends StatelessWidget {
  final Achievement achievement;
  final double badgeSize;
  final bool showAnimation;

  const _AchievementSheetCard({
    required this.achievement,
    required this.badgeSize,
    required this.showAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final badgeColor =
        AchievementService.getCategoryColor(achievement.category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(
          alpha: theme.brightness == Brightness.dark ? 214 : 245,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: badgeColor.withValues(alpha: 56),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 46 : 15,
            ),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AchievementBadge(
            achievement: achievement,
            size: badgeSize,
            isUnlocked: true,
            showShine: true,
            showAnimation: showAnimation,
          ),
          const SizedBox(height: 10),
          Text(
            achievement.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.labelLarge(context).copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '+${achievement.xpReward} XP',
            style: AppTypography.labelSmall(context).copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Enhanced achievement unlock animation with particle effects
class _EnhancedAchievementUnlock extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback? onComplete;

  const _EnhancedAchievementUnlock({
    required this.achievement,
    this.onComplete,
  });

  @override
  State<_EnhancedAchievementUnlock> createState() =>
      _EnhancedAchievementUnlockState();
}

class _EnhancedAchievementUnlockState extends State<_EnhancedAchievementUnlock>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    // Scale animation controller
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 70.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30.0,
      ),
    ]).animate(_scaleController);

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Particle animation controller
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Generate particles
    _generateParticles();

    // Start animations
    _scaleController.forward().then((_) {
      _particleController.forward();

      // Complete after all animations
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
      });
    });
  }

  void _generateParticles() {
    final color =
        AchievementService.getCategoryColor(widget.achievement.category);

    for (int i = 0; i < 40; i++) {
      _particles.add(_Particle(
        color: i % 3 == 0
            ? Colors.amber
            : i % 3 == 1
                ? color
                : Colors.white,
        size: (i % 5 + 1) * 3.0,
        angle: (i / 40) * 2 * 3.14159, // Circular distribution
        speed: (i % 3 + 2) * 0.2,
        opacity: 1.0,
      ));
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievement = widget.achievement;
    final color = AchievementService.getCategoryColor(achievement.category);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final dialogWidth = MediaQuery.of(context).size.width < 420 ? 320.0 : 360.0;

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleController, _particleController]),
      builder: (context, child) {
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Particle effects
              if (_particleController.isAnimating) ...buildParticles(),

              // Main achievement card
              Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    width: dialogWidth,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.surface,
                          colorScheme.surfaceContainerHighest.withValues(
                            alpha: isDark ? 71 : 107,
                          ),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: color.withValues(alpha: 102),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 75),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'অ্যাচিভমেন্ট আনলক হয়েছে',
                          style: AppTypography.titleLarge(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        // Enhanced badge with shine effect
                        PerspectiveBadge(
                          achievement: achievement,
                          size: 120,
                          isUnlocked: true,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          achievement.title,
                          style: AppTypography.titleMedium(context).copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          achievement.description,
                          style: AppTypography.bodyMedium(context).copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 50),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber),
                              const SizedBox(width: 8),
                              Text(
                                '+${achievement.xpReward} XP',
                                style: AppTypography.titleMedium(context).copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: widget.onComplete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Awesome!'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> buildParticles() {
    return _particles.map((particle) {
      final progress = _particleController.value;
      final distance = particle.speed * progress * 200.0; // Max distance
      final opacity = progress < 0.5
          ? particle.opacity
          : particle.opacity * (1 - (progress - 0.5) * 2);

      final dx = distance * cos(particle.angle);
      final dy = distance * sin(particle.angle);

      return Positioned(
        left: 140 + dx - particle.size / 2, // Center of the dialog
        top: 140 + dy - particle.size / 2, // Center of the dialog
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: particle.size,
            height: particle.size,
            decoration: BoxDecoration(
              color: particle.color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }).toList();
  }
}

/// Particle class for confetti effects
class _Particle {
  final Color color;
  final double size;
  final double angle; // In radians
  final double speed;
  final double opacity;

  _Particle({
    required this.color,
    required this.size,
    required this.angle,
    required this.speed,
    required this.opacity,
  });
}
