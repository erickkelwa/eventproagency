import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_routes.dart';

class _OnboardSlide {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accent;

  const _OnboardSlide({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accent,
  });
}

final _slides = [
  const _OnboardSlide(
    emoji: '🎪',
    title: 'Discover\nAmazing Events',
    subtitle:
        'Find concerts, conferences, parties & exclusive VVIP experiences happening around you.',
    accent: AppColors.primary,
  ),
  _OnboardSlide(
    emoji: '🛎️',
    title: 'Book Premium\nAgency Services',
    subtitle:
        'Arrange catering, security, VVIP transport, gaming & entertainment from one platform.',
    accent: AppColors.secondary,
  ),
  const _OnboardSlide(
    emoji: '⚡',
    title: 'Pay Instantly\nwith M-Pesa',
    subtitle:
        'Secure payments via M-Pesa STK Push. Get your e-ticket and receipt straight to your inbox.',
    accent: AppColors.tertiary,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Page View ────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, index) => _OnboardingPage(slide: _slides[index]),
          ),

          // ── Bottom Controls ───────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 56),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0),
                    AppColors.background,
                    AppColors.background,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == i
                              ? _slides[i].accent
                              : AppColors.border,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _slides[_currentPage].accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage < _slides.length - 1
                                ? 'Continue'
                                : 'Get Started',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Skip
                  if (_currentPage < _slides.length - 1)
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatefulWidget {
  final _OnboardSlide slide;
  const _OnboardingPage({required this.slide});

  @override
  State<_OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<_OnboardingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _emojiAnim;
  late Animation<double> _textAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _emojiAnim = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.elasticOut));
    _textAnim = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 220),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Emoji Icon ──────────────────────────────────
          ScaleTransition(
            scale: _emojiAnim,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.slide.accent.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
                border: Border.all(
                  color: widget.slide.accent.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  widget.slide.emoji,
                  style: const TextStyle(fontSize: 64),
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),

          // ── Title ────────────────────────────────────────
          FadeTransition(
            opacity: _textAnim,
            child: SlideTransition(
              position:
                  Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
                      .animate(_textAnim),
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [widget.slide.accent, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  widget.slide.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Subtitle ─────────────────────────────────────
          FadeTransition(
            opacity: _textAnim,
            child: Text(
              widget.slide.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}