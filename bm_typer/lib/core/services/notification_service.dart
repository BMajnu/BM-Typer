import 'dart:math';
import 'package:flutter/material.dart';
import 'package:bm_typer/core/constants/app_colors.dart';
import 'package:bm_typer/core/models/achievement_model.dart';
import 'package:bm_typer/core/services/achievement_service.dart';
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
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Achievements Unlocked!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Display badge grid for achievements
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                // Stagger animations
                final showAnimation = index % 2 == 0;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AchievementBadge(
                      achievement: achievement,
                      size: 60,
                      isUnlocked: true,
                      showShine: true,
                      showAnimation: showAnimation,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      achievement.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AchievementService.getCategoryColor(
                            achievement.category),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Total XP Earned: +$totalXp',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (onDismiss != null) {
                  onDismiss();
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Continue'),
            ),
            const SizedBox(height: 16),
          ],
        ),
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
    final random = DateTime.now().millisecondsSinceEpoch;
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
                    width: 280,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
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
                        const Text(
                          'Achievement Unlocked!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          achievement.description,
                          style: const TextStyle(fontSize: 16),
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
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
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
