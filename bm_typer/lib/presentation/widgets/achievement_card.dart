import 'package:flutter/material.dart';
import 'package:bm_typer/core/models/achievement_model.dart';
import 'package:bm_typer/core/models/user_model.dart';
import 'package:bm_typer/core/services/achievement_service.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final UserModel user;
  final bool isUnlocked;
  final bool showProgress;

  const AchievementCard({
    super.key,
    required this.achievement,
    required this.user,
    required this.isUnlocked,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUnlocked
            ? BorderSide(
                color:
                    AchievementService.getCategoryColor(achievement.category),
                width: 2,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const Divider(),
            const SizedBox(height: 8),
            _buildContent(context),
            if (showProgress && !isUnlocked) ...[
              const SizedBox(height: 12),
              _buildProgressIndicator(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final color = AchievementService.getCategoryColor(achievement.category);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isUnlocked ? color : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            achievement.icon,
            color: isUnlocked ? Colors.white : Colors.grey[600],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? color : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'XP +${achievement.xpReward}',
                style: TextStyle(
                  fontSize: 12,
                  color: isUnlocked ? Colors.amber[700] : Colors.grey[500],
                  fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        if (isUnlocked) const Icon(Icons.check_circle, color: Colors.green),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Text(
      achievement.description,
      style: TextStyle(
        fontSize: 14,
        color: isUnlocked ? Colors.black : Colors.grey[600],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    final progress = AchievementService.getProgressTowards(achievement, user);
    final color = AchievementService.getCategoryColor(achievement.category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.7)),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(progress * 100).toInt()}% Complete',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class AchievementUnlockAnimation extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback? onComplete;

  const AchievementUnlockAnimation({
    super.key,
    required this.achievement,
    this.onComplete,
  });

  @override
  State<AchievementUnlockAnimation> createState() =>
      _AchievementUnlockAnimationState();
}

class _AchievementUnlockAnimationState extends State<AchievementUnlockAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievement = widget.achievement;
    final color = AchievementService.getCategoryColor(achievement.category);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(
                  color: color,
                  width: 3,
                ),
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      achievement.icon,
                      size: 48,
                      color: color,
                    ),
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
                  Text(
                    '+${achievement.xpReward} XP',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
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
        );
      },
    );
  }
}
