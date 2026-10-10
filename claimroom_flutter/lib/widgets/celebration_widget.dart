import 'dart:math';
import 'package:flutter/material.dart';

/// Lightweight, self-contained celebration confetti overlay that bursts colorful
/// particles across the screen for 1.8 seconds when triggered.
class CelebrationOverlay extends StatefulWidget {
  final Widget child;
  final GlobalKey<CelebrationOverlayState>? overlayKey;

  const CelebrationOverlay({
    super.key,
    required this.child,
    this.overlayKey,
  });

  @override
  State<CelebrationOverlay> createState() => CelebrationOverlayState();
}

class CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1800),
          )
          ..addListener(() {
            if (mounted) setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              if (mounted) {
                setState(() {
                  _isActive = false;
                  _particles.clear();
                });
              }
            }
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Triggers a brief festive burst of confetti particles.
  void triggerCelebration() {
    _particles.clear();
    final colors = [
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEC4899), // Pink
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF14B8A6), // Teal
    ];

    for (int i = 0; i < 60; i++) {
      _particles.add(
        _ConfettiParticle(
          x: 0.5 + (_random.nextDouble() - 0.5) * 0.4,
          y: 0.25 + (_random.nextDouble() - 0.5) * 0.2,
          vx: (_random.nextDouble() - 0.5) * 1.8,
          vy: -_random.nextDouble() * 1.5 - 0.5,
          color: colors[_random.nextInt(colors.length)],
          size: 6.0 + _random.nextDouble() * 8.0,
          rotation: _random.nextDouble() * 2 * pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 8.0,
          isCircle: _random.nextBool(),
        ),
      );
    }

    _isActive = true;
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isActive)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConfettiPainter(
                  progress: _controller.value,
                  particles: _particles,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;
  double rotation;
  double rotationSpeed;
  bool isCircle;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.isCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final gravity = 2.2 * progress;

    for (final p in particles) {
      final currentX =
          (p.x * size.width) + (p.vx * size.width * 0.4 * progress);
      final currentY =
          (p.y * size.height) +
          (p.vy * size.height * 0.3 * progress) +
          (gravity * size.height * 0.5 * progress);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(p.rotation + (p.rotationSpeed * progress));

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}

/// A pulsing scale wrapper that pulses between 1.0 and 1.06 when active.
class CelebratoryPulse extends StatefulWidget {
  final Widget child;
  final bool pulse;

  const CelebratoryPulse({
    super.key,
    required this.child,
    this.pulse = true,
  });

  @override
  State<CelebratoryPulse> createState() => _CelebratoryPulseState();
}

class _CelebratoryPulseState extends State<CelebratoryPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.pulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant CelebratoryPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.pulse && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.pulse) return widget.child;
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}
