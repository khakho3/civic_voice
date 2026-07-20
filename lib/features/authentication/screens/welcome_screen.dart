import 'package:flutter/material.dart';

import 'package:civic_voice/core/theme/app_theme.dart';

/// AUTH-002 — a concise introduction to CivicVoice's citizen journey.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.onGetStarted,
    required this.onContinueAsGuest,
    required this.onLogin,
    this.initialPage = 0,
    this.onOnboardingCompleted,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onContinueAsGuest;
  final VoidCallback onLogin;
  final int initialPage;
  final VoidCallback? onOnboardingCompleted;

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

  late final PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(0, _slides.length - 1);
    _pageController = PageController(initialPage: _currentPage);
  }

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
    final maxContentWidth = context.isTabletLayout
        ? AppDimensions.maxContentWidth
        : AppBreakpoints.largeMobile;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
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
                    onPageChanged: (page) {
                      setState(() => _currentPage = page);
                      if (page == _slides.length - 1) {
                        widget.onOnboardingCompleted?.call();
                      }
                    },
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

  static const double _maxPhoneIllustrationHeight = 320;
  static const double _maxTabletIllustrationHeight = AppBreakpoints.largeMobile;
  static const double _minIllustrationHeight = 112;

  final _OnboardingContent content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxIllustrationHeight = context.isTabletLayout
        ? _maxTabletIllustrationHeight
        : _maxPhoneIllustrationHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final isCompact = availableHeight < 430;
        final topGap = isCompact ? AppSpacing.sm : AppSpacing.xxxxl;
        final contentGap = isCompact ? AppSpacing.xs : AppSpacing.sm;
        final bottomGap = isCompact ? AppSpacing.sm : AppSpacing.md;
        final illustrationHeight = (availableHeight * (isCompact ? 0.42 : 0.56))
            .clamp(_minIllustrationHeight, maxIllustrationHeight)
            .toDouble();

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: availableHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  SizedBox(height: topGap),
                  SizedBox(
                    height: illustrationHeight,
                    width: double.infinity,
                    child: Center(
                      child: Semantics(
                        image: true,
                        label: content.semanticsLabel,
                        // The onboarding assets are square (1024x1024) — a
                        // full-width contain box just floated the square in
                        // a sea of transparent letterbox. Clipping tight to
                        // the square's own bounds is what actually makes
                        // the rounded corners visible, reading as a
                        // designed illustration card rather than a dropped-
                        // in photo.
                        child: ClipRRect(
                          borderRadius: AppRadius.allLg,
                          child: Image.asset(
                            content.asset,
                            width: illustrationHeight,
                            height: illustrationHeight,
                            fit: BoxFit.cover,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: contentGap),
                  Text(
                    'CivicVoice',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: AppFontWeight.semiBold,
                    ),
                  ),
                  SizedBox(height: contentGap),
                  Text(
                    content.headline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: AppFontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: contentGap),
                  Text(
                    content.description,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: bottomGap),
                ],
              ),
            ),
          ),
        );
      },
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Visibility(
            visible: _isFinalPage,
            maintainState: true,
            maintainAnimation: true,
            maintainSize: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isFinalPage ? onContinueAsGuest : null,
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      textStyle: const TextStyle(
                        fontWeight: AppFontWeight.semiBold,
                      ),
                    ),
                    child: const Text('Continue as Guest'),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isFinalPage ? onLogin : null,
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
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
