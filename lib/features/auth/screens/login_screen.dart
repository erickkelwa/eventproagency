import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/gradient_button.dart';
import '../widgets/social_auth_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  // Staggered entry animations
  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _logoSlide;
  late final Animation<Offset> _headingSlide;
  late final Animation<Offset> _formSlide;
  late final Animation<Offset> _ctaSlide;

  // Floating orb animation
  late final AnimationController _orbCtrl;

  @override
  void initState() {
    super.initState();

    // Entry animation (1.0s total, staggered)
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    _logoSlide = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
    ));

    _headingSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.2, 0.65, curve: Curves.easeOutCubic),
    ));

    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.4, 0.85, curve: Curves.easeOutCubic),
    ));

    _ctaSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
    ));

    // Floating orbs (infinite loop)
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _entryCtrl.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(authStateProvider.notifier)
        .login(_emailCtrl.text.trim(), _passwordCtrl.text);
  }

  Future<void> _googleLogin() async {
    await ref.read(authStateProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    // Navigate on success
    ref.listen(authStateProvider, (_, next) {
      next.whenData((state) {
        if (state.isAuthenticated) {
          context.go(state.isAdmin ? AppRoutes.adminDashboard : AppRoutes.home);
        }
      });
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Animated Gold + Blue Orbs ────────────────────
          AnimatedBuilder(
            animation: _orbCtrl,
            builder: (_, _) {
              final t = _orbCtrl.value;
              return Stack(
                children: [
                  // Gold orb — top right
                  Positioned(
                    top: -60 + (t * 30),
                    right: -80 + (math.sin(t * math.pi) * 20),
                    child: _GlowOrb(
                      size: 280,
                      color: AppColors.primary,
                      opacity: 0.18,
                    ),
                  ),
                  // Blue orb — bottom left
                  Positioned(
                    bottom: -60 + (t * -20),
                    left: -80,
                    child: _GlowOrb(
                      size: 240,
                      color: AppColors.secondary,
                      opacity: 0.14,
                    ),
                  ),
                  // Small accent orb — center left
                  Positioned(
                    top: 200 + (t * 40),
                    left: -40,
                    child: _GlowOrb(
                      size: 150,
                      color: AppColors.tertiary,
                      opacity: 0.08,
                    ),
                  ),
                ],
              );
            },
          ),

          // ── Main Content ───────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 52),

                      // ── Logo ──────────────────────────────
                      SlideTransition(
                        position: _logoSlide,
                        child: Row(
                          children: [
                            // Gold icon box with FC25 card-like gloss
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.5),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.event_rounded,
                                    color: Colors.black, size: 30),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'EventPro',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  'AGENCY PLATFORM',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 44),

                      // ── Heading ───────────────────────────
                      SlideTransition(
                        position: _headingSlide,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Gold line accent
                            Container(
                              width: 36,
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Welcome back',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.8,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ShaderMask(
                              shaderCallback: (b) =>
                                  AppColors.primaryGradient.createShader(b),
                              child: const Text(
                                'Sign in to your account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // ── Form Fields ───────────────────────
                      SlideTransition(
                        position: _formSlide,
                        child: Column(
                          children: [
                            AuthTextField(
                              controller: _emailCtrl,
                              label: 'Email address',
                              hint: 'you@example.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Enter your email';
                                }
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                    .hasMatch(v)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            AuthTextField(
                              controller: _passwordCtrl,
                              label: 'Password',
                              hint: '••••••••',
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onEditingComplete: isLoading ? null : _login,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textMuted,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Enter your password';
                                }
                                if (v.length < 6) return 'Minimum 6 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),

                            // Forgot password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () =>
                                    context.push(AppRoutes.forgotPassword),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: ShaderMask(
                                  shaderCallback: (b) =>
                                      AppColors.primaryGradient.createShader(b),
                                  child: const Text(
                                    'Forgot password?',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── CTA + Socials ─────────────────────
                      SlideTransition(
                        position: _ctaSlide,
                        child: Column(
                          children: [
                            // Sign In button
                            GradientButton(
                              id: 'login_submit_btn',
                              onPressed: isLoading ? null : _login,
                              isLoading: isLoading,
                              label: 'Sign In',
                              icon: Icons.arrow_forward_rounded,
                            ),
                            const SizedBox(height: 12),

                            // ── Try Demo ──────────────────────
                            _DemoButton(
                              isLoading: isLoading,
                              onTap: () async {
                                await ref
                                    .read(authStateProvider.notifier)
                                    .demoLogin();
                              },
                            ),
                            const SizedBox(height: 20),

                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                      color: AppColors.border, thickness: 0.8),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  child: Text(
                                    'or continue with',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                      color: AppColors.border, thickness: 0.8),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Google button
                            SocialAuthButton(
                              id: 'google_login_btn',
                              onPressed: isLoading ? null : _googleLogin,
                              label: 'Continue with Google',
                              iconColor: const Color(0xFF4285F4),
                            ),
                            const SizedBox(height: 36),

                            // Register link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account?  ",
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      context.push(AppRoutes.register),
                                  child: ShaderMask(
                                    shaderCallback: (b) =>
                                        AppColors.primaryGradient.createShader(b),
                                    child: const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
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

/// Radial glow orb for background decoration
class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GlowOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: opacity), Colors.transparent],
        ),
      ),
    );
  }
}

/// One-tap demo access button
class _DemoButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _DemoButton({required this.isLoading, required this.onTap});

  @override
  State<_DemoButton> createState() => _DemoButtonState();
}

class _DemoButtonState extends State<_DemoButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isLoading ? null : (_) => _ctrl.forward(),
      onTapUp: widget.isLoading ? null : (_) => _ctrl.reverse(),
      onTapCancel: widget.isLoading ? null : () => _ctrl.reverse(),
      onTap: widget.isLoading ? null : widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.secondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Try Demo Account',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'NO SIGNUP',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}