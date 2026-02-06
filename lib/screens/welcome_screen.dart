import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

/// StudyScape welcome/onboarding screen with geometric pattern background,
/// translucent card, and Create Account / Login actions.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const Color _bgBlue = Color(0xFF212B58);
  static const Color _welcomeOrange = Color(0xFFFF8C00);
  static const Color _buttonStart = Color(0xFFE0B47F);
  static const Color _buttonEnd = Color(0xFFD4A772);
  static const Color _patternColor = Color(0x1AFFFFFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Dark blue background
          Container(color: _bgBlue),
          // Geometric pattern overlay
          CustomPaint(
            painter: _GeometricPatternPainter(color: _patternColor),
            size: Size.infinite,
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 48),
                // App title
                Text(
                  'StudyScape',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                // Translucent card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(28, 32, 28, 36),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome',
                              style: TextStyle(
                                color: _welcomeOrange,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Sign in to join the world of active learners.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 28),
                            _WelcomeButton(
                              label: 'Create Account',
                              onPressed: () {},
                            ),
                            const SizedBox(height: 14),
                            _WelcomeButton(
                              label: 'Login',
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill-shaped golden-tan gradient button.
class _WelcomeButton extends StatelessWidget {
  const _WelcomeButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              WelcomeScreen._buttonStart,
              WelcomeScreen._buttonEnd,
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(26),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a subtle geometric pattern (circles, triangles, squares, etc.).
class _GeometricPatternPainter extends CustomPainter {
  _GeometricPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final random = _SeededRandom(42);
    final shapes = <void Function(Canvas, double, double)>[
      (c, x, y) {
        c.drawCircle(Offset(x, y), 4 + random.next() * 8, paint);
      },
      (c, x, y) {
        final r = 6 + random.next() * 10;
        c.drawRect(
          Rect.fromCenter(center: Offset(x, y), width: r * 2, height: r * 2),
          paint,
        );
      },
      (c, x, y) {
        final r = 5 + random.next() * 8;
        final path = Path()
          ..moveTo(x, y - r)
          ..lineTo(x + r, y + r)
          ..lineTo(x - r, y + r)
          ..close();
        c.drawPath(path, paint);
      },
      (c, x, y) {
        final r = 4 + random.next() * 6;
        final path = Path();
        for (var i = 0; i < 6; i++) {
          final angle = (i * 60) * math.pi / 180;
          final px = x + r * math.cos(angle);
          final py = y + r * math.sin(angle);
          if (i == 0) path.moveTo(px, py);
          else path.lineTo(px, py);
        }
        path.close();
        c.drawPath(path, paint);
      },
      (c, x, y) {
        final len = 8 + random.next() * 16;
        c.drawLine(Offset(x - len, y), Offset(x + len, y), paint);
      },
    ];

    for (var i = 0; i < 80; i++) {
      final x = random.next() * size.width;
      final y = random.next() * size.height;
      shapes[random.nextInt(shapes.length)](canvas, x, y);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Simple seeded random for deterministic pattern.
class _SeededRandom {
  _SeededRandom(this._seed);

  double _seed;

  double next() {
    _seed = (_seed * 1103515245 + 12345) % 0x100000000;
    return _seed / 0x100000000;
  }

  int nextInt(int max) => (next() * max).floor();
}
