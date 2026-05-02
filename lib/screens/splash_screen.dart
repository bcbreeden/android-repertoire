import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/piece_provider.dart';
import '../utils/constants.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _progressController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    _progressController = AnimationController(vsync: this, value: 0);
    // Animate to 70% while loading runs in the background
    _progressController.animateTo(
      0.7,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<PieceProvider>().loadPieces();
    if (!mounted) return;

    // Complete the bar
    await _progressController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainScreen(),
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              _Logo(),
              const SizedBox(height: 24),
              const Text(
                'Repertoire',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track your practice journey',
                style: TextStyle(
                  color: kTextSecondary.withOpacity(0.65),
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(flex: 3),
              _ProgressFooter(controller: _progressController),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Logo icon with glow ───────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kGoldColor.withOpacity(0.07),
        border: Border.all(color: kGoldColor.withOpacity(0.22), width: 1),
        boxShadow: [
          BoxShadow(
            color: kGoldColor.withOpacity(0.20),
            blurRadius: 36,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Icon(Icons.piano, color: kGoldColor, size: 46),
    );
  }
}

// ── Progress bar + label ──────────────────────────────────────────────────────

class _ProgressFooter extends StatelessWidget {
  final AnimationController controller;
  const _ProgressFooter({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 0, 48, 60),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: controller.value,
                backgroundColor: kDividerColor,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(kGoldColor),
                minHeight: 2,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Loading your songs\u2026',
            style: TextStyle(
              color: kTextSecondary.withOpacity(0.40),
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
