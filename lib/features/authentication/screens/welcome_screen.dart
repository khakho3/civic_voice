import 'package:flutter/material.dart';

import 'package:civic_voice/core/theme/app_theme.dart';

/// AUTH-002 — a concise introduction to CivicVoice's citizen journey.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.onGetStarted,
    required this.onContinueAsGuest,
    required this.onLogin,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onContinueAsGuest;
  final VoidCallback onLogin;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const _slides = <_OnboardingContent>[
    _OnboardingContent(
      headline: 'Report.',
      description: 'See an issue in your community? Report it in seconds.',
      asset: AppAssets.onboardingReport,
      semanticsLabel: 'Citizen reporting a community issue',
    ),
    _OnboardingContent(
      headline: 'Track.',
      description: "Follow every report's progress in real time.",
      asset: AppAssets.onboardingTrack,
      semanticsLabel: 'Citizen tracking the progress of a report',
    ),
    _OnboardingContent(
      headline: 'Resolve.',
      description:
          'Work together with local government to build a better community.',
      asset: AppAssets.onboardingResolve,
      semanticsLabel: 'Community members working together to resolve an issue',
    ),
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _animateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: AppMotion.duration(context, AppMotionDuration.pageTransition),
      curve: AppMotionCurve.emphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.standardMobile,
            ),
            child: Column(
              children: [
                _OnboardingSkip(
                  isVisible: _currentPage < _slides.length - 1,
                  onPressed: () => _animateToPage(_slides.length - 1),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    itemBuilder: (context, index) =>
                        _OnboardingSlide(content: _slides[index]),
                  ),
                ),
                _OnboardingActions(
                  currentPage: _currentPage,
                  onNext: () => _animateToPage(_currentPage + 1),
                  onGetStarted: widget.onGetStarted,
                  onContinueAsGuest: widget.onContinueAsGuest,
                  onLogin: widget.onLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.content});

  final _OnboardingContent content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xxxxl),
                SizedBox(
                  height: 320,
                  width: double.infinity,
                  child: Semantics(
                    image: true,
                    label: content.semanticsLabel,
                    child: Image.asset(
                      content.asset,
                      width: double.infinity,
                      height: 320,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'CivicVoice',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: AppFontWeight.semiBold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  content.headline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: AppFontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  content.description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingSkip extends StatelessWidget {
  const _OnboardingSkip({required this.isVisible, required this.onPressed});

  final bool isVisible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: AppSpacing.xxxl,
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        child: Align(
          alignment: Alignment.centerRight,
          child: AnimatedOpacity(
            opacity: isVisible ? 1 : 0,
            duration: AppMotion.duration(
              context,
              AppMotionDuration.pageTransition,
            ),
            child: IgnorePointer(
              ignoring: !isVisible,
              child: ExcludeSemantics(
                excluding: !isVisible,
                child: TextButton(
                  onPressed: onPressed,
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onSurfaceVariant,
                  ),
                  child: const Text('Skip'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingActions extends StatelessWidget {
  const _OnboardingActions({
    required this.currentPage,
    required this.onNext,
    required this.onGetStarted,
    required this.onContinueAsGuest,
    required this.onLogin,
  });

  final int currentPage;
  final VoidCallback onNext;
  final VoidCallback onGetStarted;
  final VoidCallback onContinueAsGuest;
  final VoidCallback onLogin;

  bool get _isFinalPage => currentPage == 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 208,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          children: [
            _PageIndicator(currentPage: currentPage),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isFinalPage ? onGetStarted : onNext,
                child: Text(_isFinalPage ? 'Get Started' : 'Next'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: AppSpacing.xxxl,
              width: double.infinity,
              child: _isFinalPage
                  ? TextButton(
                      onPressed: onContinueAsGuest,
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.onSurface,
                        textStyle: const TextStyle(
                          fontWeight: AppFontWeight.semiBold,
                        ),
                      ),
                      child: const Text('Continue as Guest'),
                    )
                  : null,
            ),
            const Spacer(),
            SizedBox(
              height: AppSpacing.xxxl,
              child: _isFinalPage
                  ? TextButton(
                      onPressed: onLogin,
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.onSurfaceVariant,
                        textStyle: theme.textTheme.bodySmall,
                      ),
                      child: Text.rich(
                        TextSpan(
                          text: 'Already have an account? ',
                          children: [
                            TextSpan(
                              text: 'Log in',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: AppFontWeight.semiBold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.currentPage});

  final int currentPage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Page ${currentPage + 1} of 3',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (index) => Container(
            width: index == currentPage ? AppSpacing.lg : AppSpacing.sm,
            height: AppSpacing.sm,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            decoration: BoxDecoration(
              color: index == currentPage
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              borderRadius: AppRadius.allSm,
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingContent {
  const _OnboardingContent({
    required this.headline,
    required this.description,
    required this.asset,
    required this.semanticsLabel,
  });

  final String headline;
  final String description;
  final String asset;
  final String semanticsLabel;
}
