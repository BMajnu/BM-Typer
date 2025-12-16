import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:bm_typer/core/theme/theme.dart';
import 'package:bm_typer/core/models/achievement_model.dart';
import 'package:bm_typer/core/services/achievement_service.dart';

/// আধুনিক অ্যাচিভমেন্ট ব্যাজ
/// 
/// শাইন এবং পালস অ্যানিমেশন সহ।
class AchievementBadge extends StatefulWidget {
  final Achievement achievement;
  final double size;
  final bool isUnlocked;
  final bool showShine;
  final bool showAnimation;
  final VoidCallback? onTap;

  const AchievementBadge({
    super.key,
    required this.achievement,
    this.size = 80.0,
    this.isUnlocked = false,
    this.showShine = false,
    this.showAnimation = false,
    this.onTap,
  });

  @override
  State<AchievementBadge> createState() => _AchievementBadgeState();
}

class _AchievementBadgeState extends State<AchievementBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _shineAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.1)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50.0,
      ),
    ]).animate(_controller);

    _rotateAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.03)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.03, end: -0.03)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.03, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25.0,
      ),
    ]).animate(_controller);

    _shineAnimation = Tween<double>(begin: -1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
      ),
    );

    if (widget.showAnimation) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AchievementBadge oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.showAnimation != oldWidget.showAnimation) {
      if (widget.showAnimation) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = AchievementService.getCategoryColor(widget.achievement.category);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.showAnimation ? _pulseAnimation.value : 1.0,
            child: Transform.rotate(
              angle: widget.showAnimation ? _rotateAnimation.value : 0.0,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  children: [
                    // Badge base with gradient
                    _buildBadgeBase(color),
                    
                    // Shine effect
                    if (widget.showShine && widget.isUnlocked)
                      _buildShineEffect(),
                    
                    // Icon
                    _buildBadgeIcon(color),
                    
                    // Locked overlay
                    if (!widget.isUnlocked) _buildLockedOverlay(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadgeBase(Color color) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: widget.isUnlocked
            ? RadialGradient(
                center: const Alignment(-0.3, -0.3),
                colors: [
                  color.withOpacity(0.9),
                  color,
                  color.withOpacity(0.8),
                ],
                stops: const [0.0, 0.5, 1.0],
              )
            : RadialGradient(
                colors: [
                  Colors.grey[400]!,
                  Colors.grey[500]!,
                ],
              ),
        border: Border.all(
          color: widget.isUnlocked ? Colors.white.withOpacity(0.5) : Colors.grey[400]!,
          width: widget.size * 0.04,
        ),
        boxShadow: widget.isUnlocked
            ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: widget.size * 0.2,
                  spreadRadius: widget.size * 0.02,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: widget.size * 0.1,
                  offset: Offset(0, widget.size * 0.05),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: widget.size * 0.08,
                  offset: Offset(0, widget.size * 0.03),
                ),
              ],
      ),
      // Inner ring
      child: Center(
        child: Container(
          width: widget.size * 0.8,
          height: widget.size * 0.8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isUnlocked
                  ? Colors.white.withOpacity(0.3)
                  : Colors.grey[400]!.withOpacity(0.3),
              width: widget.size * 0.02,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShineEffect() {
    return AnimatedBuilder(
      animation: _shineAnimation,
      builder: (context, child) {
        return ClipOval(
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Transform.translate(
                offset: Offset(
                  widget.size * _shineAnimation.value,
                  0,
                ),
                child: Container(
                  width: widget.size * 0.3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.5),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadgeIcon(Color color) {
    return Center(
      child: Icon(
        widget.achievement.icon,
        color: widget.isUnlocked ? Colors.white : Colors.grey[500],
        size: widget.size * 0.45,
      ),
    );
  }

  Widget _buildLockedOverlay() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.4),
      ),
      child: Center(
        child: Icon(
          Icons.lock_rounded,
          color: Colors.white.withOpacity(0.8),
          size: widget.size * 0.25,
        ),
      ),
    );
  }
}

/// পারস্পেক্টিভ ব্যাজ - 3D ইফেক্ট সহ
class PerspectiveBadge extends StatefulWidget {
  final Achievement achievement;
  final double size;
  final bool isUnlocked;
  final VoidCallback? onTap;

  const PerspectiveBadge({
    super.key,
    required this.achievement,
    this.size = 100.0,
    this.isUnlocked = false,
    this.onTap,
  });

  @override
  State<PerspectiveBadge> createState() => _PerspectiveBadgeState();
}

class _PerspectiveBadgeState extends State<PerspectiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    );

    _flipAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.1)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.1, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50.0,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool isHovering) {
    setState(() {
      _isHovering = isHovering;
      if (isHovering) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = AchievementService.getCategoryColor(widget.achievement.category);
    final baseColor = widget.isUnlocked ? color : Colors.grey[400]!;

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(_isHovering ? _flipAnimation.value : 0)
                ..rotateY(_isHovering ? _flipAnimation.value * 0.5 : 0),
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      baseColor.withOpacity(0.9),
                      baseColor,
                    ],
                    center: const Alignment(0.2, -0.3),
                    focal: const Alignment(0.0, -0.1),
                    focalRadius: 0.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: baseColor.withOpacity(0.4),
                      blurRadius: widget.size * 0.12,
                      spreadRadius: widget.size * 0.01,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: widget.size * 0.06,
                      offset: Offset(0, widget.size * 0.03),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Inner ring
                    Center(
                      child: Container(
                        width: widget.size * 0.85,
                        height: widget.size * 0.85,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: widget.size * 0.03,
                          ),
                        ),
                      ),
                    ),

                    // Icon
                    Center(
                      child: Icon(
                        widget.achievement.icon,
                        color: Colors.white,
                        size: widget.size * 0.45,
                      ),
                    ),

                    // Shine effect
                    if (widget.isUnlocked)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: widget.size * 0.5,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Lock overlay
                    if (!widget.isUnlocked)
                      Center(
                        child: Container(
                          width: widget.size,
                          height: widget.size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.45),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.lock_rounded,
                              color: Colors.white.withOpacity(0.85),
                              size: widget.size * 0.28,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// অ্যাচিভমেন্ট ব্যাজ গ্রিড
class AchievementBadgeGrid extends StatelessWidget {
  final List<Achievement> achievements;
  final List<String> unlockedIds;
  final double spacing;
  final double badgeSize;
  final Function(Achievement)? onTap;
  final bool usePerspectiveBadges;

  const AchievementBadgeGrid({
    super.key,
    required this.achievements,
    required this.unlockedIds,
    this.spacing = 16.0,
    this.badgeSize = 80.0,
    this.onTap,
    this.usePerspectiveBadges = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _calculateCrossAxisCount(context),
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 0.85,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        final isUnlocked = unlockedIds.contains(achievement.id);

        Widget badgeWidget;
        if (usePerspectiveBadges) {
          badgeWidget = PerspectiveBadge(
            achievement: achievement,
            isUnlocked: isUnlocked,
            size: badgeSize,
            onTap: onTap != null ? () => onTap!(achievement) : null,
          );
        } else {
          badgeWidget = AchievementBadge(
            achievement: achievement,
            isUnlocked: isUnlocked,
            size: badgeSize,
            showShine: isUnlocked,
            showAnimation: isUnlocked && index % 3 == 0,
            onTap: onTap != null ? () => onTap!(achievement) : null,
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            badgeWidget,
            SizedBox(height: AppSpacing.xs),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: AppTypography.labelSmall(context).copyWith(
                fontWeight: FontWeight.w600,
                color: isUnlocked
                    ? AchievementService.getCategoryColor(achievement.category)
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width > 1000) {
      return 5;
    } else if (width > 700) {
      return 4;
    } else if (width > 500) {
      return 3;
    } else {
      return 2;
    }
  }
}
