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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;

  // Current step for multi-step feel (0 = basic info, 1 = password)
  int _step = 0;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _headerSlide;
  late final Animation<Offset> _formSlide;

  late final AnimationController _orbCtrl;
  late final AnimationController _stepCtrl;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    ));
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
    ));

    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    _stepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _entryCtrl.dispose();
    _orbCtrl.dispose();
    _stepCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please accept the Terms & Conditions'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    await ref.read(authStateProvider.notifier).register(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          passwordConfirmation: _confirmCtrl.text,
          phone: _phoneCtrl.text.trim().isNotEmpty
              ? _phoneCtrl.text.trim()
              : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

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
          // ── Animated Orbs ────────────────────────────────
          AnimatedBuilder(
            animation: _orbCtrl,
            builder: (_, _) {
              final t = _orbCtrl.value;
              return Stack(
                children: [
                  Positioned(
                    top: -80 + (math.sin(t * math.pi) * 25),
                    left: -80,
                    child: _GlowOrb(size: 260, color: AppColors.primary, opacity: 0.16),
                  ),
                  Positioned(
                    bottom: -60 + (t * 30),
                    right: -60,
                    child: _GlowOrb(size: 220, color: AppColors.secondary, opacity: 0.13),
                  ),
                ],
              );
            },
          ),

          // ── Main Content ────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Header ──────────────────────────────
                FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _headerSlide,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        children: [
                          // Back button
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(13),
                                border:
                                    Border.all(color: AppColors.border),
                              ),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: AppColors.textPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              ShaderMask(
                                shaderCallback: (b) =>
                                    AppColors.primaryGradient.createShader(b),
                                child: const Text(
                                  'Join the elite event experience',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Progress indicator ───────────────────
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _StepProgressBar(currentStep: _step, totalSteps: 2),
                  ),
                ),
                const SizedBox(height: 6),

                // ── Scrollable Form ──────────────────────
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _formSlide,
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding:
                            const EdgeInsets.fromLTRB(20, 20, 20, 32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Step indicator label ──
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Step ${_step + 1} of 2',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _step == 0
                                        ? 'Personal Info'
                                        : 'Secure Your Account',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // ── Step 0: Name, Email, Phone ──
                              if (_step == 0) ...[
                                AuthTextField(
                                  controller: _nameCtrl,
                                  label: 'Full Name',
                                  hint: 'John Doe',
                                  prefixIcon: Icons.person_outline_rounded,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Enter your full name'
                                      : null,
                                ),
                                const SizedBox(height: 18),
                                AuthTextField(
                                  controller: _emailCtrl,
                                  label: 'Email Address',
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
                                  controller: _phoneCtrl,
                                  label: 'Phone Number (Optional)',
                                  hint: '+254 7XX XXX XXX',
                                  prefixIcon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.done,
                                ),
                                const SizedBox(height: 32),

                                // Next button
                                GradientButton(
                                  label: 'Continue',
                                  icon: Icons.arrow_forward_rounded,
                                  onPressed: () {
                                    // Validate step 0 fields only
                                    if (_nameCtrl.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content:
                                            Text('Please enter your name'),
                                      ));
                                      return;
                                    }
                                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                        .hasMatch(_emailCtrl.text)) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content: Text(
                                            'Please enter a valid email'),
                                      ));
                                      return;
                                    }
                                    setState(() => _step = 1);
                                  },
                                ),
                              ],

                              // ── Step 1: Password ──────────
                              if (_step == 1) ...[
                                AuthTextField(
                                  controller: _passwordCtrl,
                                  label: 'Password',
                                  hint: 'Min. 8 characters',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.next,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textMuted,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Enter a password';
                                    }
                                    if (v.length < 8) {
                                      return 'Minimum 8 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),
                                AuthTextField(
                                  controller: _confirmCtrl,
                                  label: 'Confirm Password',
                                  hint: '••••••••',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  obscureText: _obscureConfirm,
                                  textInputAction: TextInputAction.done,
                                  onEditingComplete: isLoading ? null : _register,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textMuted,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscureConfirm = !_obscureConfirm),
                                  ),
                                  validator: (v) {
                                    if (v != _passwordCtrl.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 22),

                                // Password strength hint
                                AnimatedBuilder(
                                  animation: _passwordCtrl,
                                  builder: (_, _) => _PasswordStrengthBar(
                                      password: _passwordCtrl.text),
                                ),
                                const SizedBox(height: 22),

                                // Terms checkbox
                                GestureDetector(
                                  onTap: () => setState(
                                      () => _acceptedTerms = !_acceptedTerms),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: _acceptedTerms
                                                ? AppColors.primary
                                                : AppColors.border,
                                            width: 1.5,
                                          ),
                                          gradient: _acceptedTerms
                                              ? AppColors.primaryGradient
                                              : null,
                                        ),
                                        child: _acceptedTerms
                                            ? const Icon(Icons.check_rounded,
                                                color: Colors.black, size: 14)
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                                color:
                                                    AppColors.textSecondary,
                                                fontSize: 13,
                                                height: 1.5),
                                            children: [
                                              const TextSpan(
                                                  text: 'I agree to the '),
                                              TextSpan(
                                                text: 'Terms & Conditions',
                                                style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w700,
                                                  decoration:
                                                      TextDecoration.underline,
                                                  decorationColor:
                                                      AppColors.primary,
                                                ),
                                              ),
                                              const TextSpan(text: ' and '),
                                              TextSpan(
                                                text: 'Privacy Policy',
                                                style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w700,
                                                  decoration:
                                                      TextDecoration.underline,
                                                  decorationColor:
                                                      AppColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // Create account button
                                GradientButton(
                                  id: 'register_submit_btn',
                                  onPressed: isLoading ? null : _register,
                                  isLoading: isLoading,
                                  label: 'Create Account',
                                  icon: Icons.rocket_launch_rounded,
                                ),
                                const SizedBox(height: 24),

                                // Or sign up with Google
                                Row(
                                  children: [
                                    Expanded(
                                        child: Divider(
                                            color: AppColors.border,
                                            thickness: 0.8)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14),
                                      child: Text(
                                        'or sign up with',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                        child: Divider(
                                            color: AppColors.border,
                                            thickness: 0.8)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SocialAuthButton(
                                  id: 'google_register_btn',
                                  onPressed: isLoading
                                      ? null
                                      : () => ref
                                          .read(authStateProvider.notifier)
                                          .signInWithGoogle(),
                                  label: 'Continue with Google',
                                  iconColor: const Color(0xFF4285F4),
                                ),
                              ],

                              const SizedBox(height: 28),

                              // Sign in link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account?  ',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => context.pop(),
                                    child: ShaderMask(
                                      shaderCallback: (b) =>
                                          AppColors.primaryGradient.createShader(b),
                                      child: const Text(
                                        'Sign In',
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
                            ],
                          ),
                        ),
                      ),
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

// ── Step Progress Bar ─────────────────────────────────────────────────────────
class _StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _StepProgressBar({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final isCompleted = i < currentStep;
        final isActive = i == currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: isActive || isCompleted
                        ? AppColors.primaryGradient
                        : null,
                    color: isActive || isCompleted ? null : AppColors.border,
                  ),
                ),
              ),
              if (i < totalSteps - 1) const SizedBox(width: 6),
            ],
          ),
        );
      }),
    );
  }
}

// ── Password Strength Bar ─────────────────────────────────────────────────────
class _PasswordStrengthBar extends StatelessWidget {
  final String password;
  const _PasswordStrengthBar({required this.password});

  int _strength() {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*]'))) score++;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final strength = _strength();
    final label = ['', 'Weak', 'Fair', 'Good', 'Strong'][strength];
    final color = [
      Colors.transparent,
      AppColors.error,
      AppColors.warning,
      AppColors.secondary,
      AppColors.success,
    ][strength];

    if (password.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ...List.generate(4, (i) {
              final active = i < strength;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 3 ? 6 : 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: active ? color : AppColors.border,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                label,
                key: ValueKey(label),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Reusable glow orb
class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _GlowOrb({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient:
            RadialGradient(colors: [color.withValues(alpha: opacity), Colors.transparent]),
      ),
    );
  }
}