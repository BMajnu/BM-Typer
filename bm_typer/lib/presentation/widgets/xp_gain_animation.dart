import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:bm_typer/core/constants/app_colors.dart';

class XPGainAnimation extends StatefulWidget {
  final int xpAmount;
  final VoidCallback? onComplete;

  const XPGainAnimation({
    super.key,
    required this.xpAmount,
    this.onComplete,
  });

  @override
  State<XPGainAnimation> createState() => _XPGainAnimationState();
}

class _XPGainAnimationState extends State<XPGainAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _moveAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Animation sequence: appear (scale up) -> move up -> fade out
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 0.8)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_controller);

    _moveAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOutQuad))
        .animate(_controller);

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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: Offset(0, -60 * _moveAnimation.value),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: _buildXPBubble(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildXPBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.amber, Colors.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildShinyIcon(),
          const SizedBox(width: 4),
          Text(
            '+${widget.xpAmount} XP',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShinyIcon() {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          colors: const [Colors.yellow, Colors.white, Colors.yellow],
          stops: [0.0, _controller.value, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      child: const Icon(
        Icons.star,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

class XPGainOverlay extends StatelessWidget {
  final int xpAmount;

  const XPGainOverlay({
    super.key,
    required this.xpAmount,
  });

  static void show(BuildContext context, int xpAmount) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      pageBuilder: (context, animation, secondaryAnimation) {
        return XPGainOverlay(xpAmount: xpAmount);
      },
      transitionDuration: const Duration(milliseconds: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: XPGainAnimation(
          xpAmount: xpAmount,
          onComplete: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

class XPParticle {
  Offset position;
  Color color;
  double size;
  double velocity;
  double angle;
  double opacity;

  XPParticle({
    required this.position,
    required this.color,
    required this.size,
    required this.velocity,
    required this.angle,
    this.opacity = 1.0,
  });

  void update() {
    final dx = velocity * math.cos(angle);
    final dy = velocity * math.sin(angle);
    position = position.translate(dx, dy);
    opacity -= 0.02;
    velocity *= 0.95;
  }
}

class XPBurstAnimation extends StatefulWidget {
  final int xpAmount;
  final Offset position;
  final VoidCallback? onComplete;

  const XPBurstAnimation({
    super.key,
    required this.xpAmount,
    required this.position,
    this.onComplete,
  });

  @override
  State<XPBurstAnimation> createState() => _XPBurstAnimationState();
}

class _XPBurstAnimationState extends State<XPBurstAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<XPParticle> _particles = [];
  final int _particleCount = 15;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _initializeParticles();
    _controller.forward().then((_) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  void _initializeParticles() {
    final colors = [
      Colors.amber.shade300,
      Colors.amber.shade400,
      Colors.orange.shade300,
      Colors.orange.shade400,
      Colors.yellow,
    ];

    for (int i = 0; i < _particleCount; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final velocity = 2 + _random.nextDouble() * 3;
      final size = 6 + _random.nextDouble() * 6;

      _particles.add(
        XPParticle(
          position: widget.position,
          color: colors[_random.nextInt(colors.length)],
          size: size,
          velocity: velocity,
          angle: angle,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Update particles
        for (final particle in _particles) {
          particle.update();
        }

        return Stack(
          children: [
            // Draw particles
            ..._particles
                .where((particle) => particle.opacity > 0)
                .map((particle) => Positioned(
                      left: particle.position.dx - (particle.size / 2),
                      top: particle.position.dy - (particle.size / 2),
                      child: Opacity(
                        opacity: particle.opacity,
                        child: Container(
                          width: particle.size,
                          height: particle.size,
                          decoration: BoxDecoration(
                            color: particle.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: particle.color.withOpacity(0.5),
                                blurRadius: 2,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
            // Show XP text
            Positioned(
              left: widget.position.dx - 40,
              top: widget.position.dy - 20,
              child: XPGainAnimation(
                xpAmount: widget.xpAmount,
                onComplete: () {},
              ),
            ),
          ],
        );
      },
    );
  }
}
