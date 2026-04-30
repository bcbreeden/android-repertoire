import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/constants.dart';

class CelebrationScreen extends StatefulWidget {
  final String pieceName;
  const CelebrationScreen({super.key, required this.pieceName});

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _textController;
  late Animation<double> _textScale;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _textScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.elasticOut),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _particleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1400),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) => CustomPaint(
              painter: _ConfettiPainter(_particleController.value),
              size: Size.infinite,
            ),
          ),
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _textOpacity,
                child: ScaleTransition(
                  scale: _textScale,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: kGoldColor, size: 80),
                        const SizedBox(height: 24),
                        Text(
                          widget.pieceName,
                          style: const TextStyle(
                            color: kGoldLight,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'is in your Repertoire!',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kGoldColor,
                            foregroundColor: const Color(0xFF1A1200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 48, vertical: 16),
                            textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          child: const Text('Dismiss'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final Random _random = Random(42);
  static const int _count = 60;

  _ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [kGoldColor, kGoldLight, Colors.white, const Color(0xFFFFE082)];
    for (int i = 0; i < _count; i++) {
      final seed = i * 137.5;
      final x = ((_random.nextDouble() * size.width) + seed) % size.width;
      final startY = -20.0 - (_random.nextDouble() * size.height * 0.5);
      final speed = 0.3 + _random.nextDouble() * 0.7;
      final y = startY + (size.height + 40) * ((progress * speed + i / _count) % 1.0);
      final color = colors[i % colors.length];
      final paint = Paint()..color = color.withOpacity(0.8);
      final w = 4.0 + _random.nextDouble() * 6;
      final h = 4.0 + _random.nextDouble() * 6;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * 2 * pi + seed);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: w, height: h), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
