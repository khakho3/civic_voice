import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'citizen_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String routeName = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const String _motto = "Let's build together";

  Timer? _timer;
  late final AnimationController _mottoController;

  @override
  void initState() {
    super.initState();
    _mottoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
    _timer = Timer(const Duration(milliseconds: 3500), _openDashboard);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mottoController.dispose();
    super.dispose();
  }

  void _openDashboard() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(CitizenDashboardScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;
            final logoSize = compact ? 104.0 : 128.0;

            return Center(
              child: Padding(
                padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      AppAssets.logoApp,
                      width: logoSize,
                      height: logoSize,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'CivicVoice',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: AppFontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Report. Track. Resolve.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _AnimatedMotto(
                      text: _motto,
                      animation: _mottoController,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(strokeWidth: 3),
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

class _AnimatedMotto extends StatelessWidget {
  const _AnimatedMotto({required this.text, required this.animation});

  final String text;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final shimmerPosition = (animation.value * 2.4) - 0.7;

        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(shimmerPosition - 1, 0),
              end: Alignment(shimmerPosition + 1, 0),
              colors: const [
                Color(0xFF1D4ED8),
                Color(0xFF38BDF8),
                Color(0xFFE0F2FE),
                Color(0xFF2563EB),
              ],
              stops: const [0, 0.42, 0.55, 1],
            ).createShader(bounds);
          },
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            children: [
              for (var index = 0; index < text.length; index++)
                _MottoGlyph(
                  character: text[index],
                  progress: _glyphProgress(index),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppFontWeight.bold,
                    letterSpacing: 0,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  double _glyphProgress(int index) {
    final start = index * 0.028;
    final end = start + 0.42 > 1.0 ? 1.0 : start + 0.42;
    final rawProgress = (animation.value - start) / (end - start);
    final progress = _clampUnit(rawProgress);
    return Curves.easeOutBack.transform(progress);
  }
}

class _MottoGlyph extends StatelessWidget {
  const _MottoGlyph({
    required this.character,
    required this.progress,
    required this.style,
  });

  final String character;
  final double progress;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final visibleCharacter = character == ' ' ? '\u00A0' : character;
    final opacity = _clampUnit(progress);

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, 16 * (1 - progress)),
        child: Transform.scale(
          scale: 0.92 + (0.08 * progress),
          child: Text(visibleCharacter, style: style),
        ),
      ),
    );
  }
}

double _clampUnit(double value) {
  if (value < 0) return 0;
  if (value > 1) return 1;
  return value;
}
