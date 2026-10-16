import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/gradient_button.dart';

/// Styled "Set New Password" page.
///
/// Opened directly in-app (for a signed-in user) or via the reset link
/// deep link `/reset-password?oobCode=XXXX` — when an [oobCode] is present
/// the password is reset with Firebase `confirmPasswordReset`.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? oobCode;
  const ResetPasswordScreen({super.key, this.oobCode});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _done = false;

  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (widget.oobCode != null && widget.oobCode!.isNotEmpty) {
        // Reset via the code from the email link (works even when signed out)
        await FirebaseAuth.instance.confirmPasswordReset(
          code: widget.oobCode!,
          newPassword: _passwordCtrl.text,
        );
      } else {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception(
              'Your reset link is missing or expired. Request a new one.');
        }
        // Signed-in user (e.g. linking a password to a Google-only account)
        await ref
            .read(authStateProvider.notifier)
            .setPassword(_passwordCtrl.text);
      }
      if (mounted) setState(() => _done = true);
    } on FirebaseAuthException catch (e) {
      _showError(switch (e.code) {
        'invalid-continuation-url-or-code' =>
          'This reset link is invalid or has expired. Request a new one.',
        'weak-password' => 'Please choose a stronger password.',
        _ => e.message ?? 'Could not reset your password.',
      });
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: FadeTransition(
            opacity: _animCtrl,
            child: _done ? _buildSuccess() : _buildForm(),
          ),
        ),
      ),
    );
  }

  // ── Form state ───────────────────────────────────────────
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          IconButton(
            onPressed: () => Navigator.canPop(context)
                ? Navigator.pop(context)
                : context.go(AppRoutes.login),
            icon:
                Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 24),

          // Key icon badge
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: const Icon(Icons.key_rounded,
                color: Colors.white, size: 34),
          ),
          const SizedBox(height: 28),
          Text(
            'Set New Password 🔑',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.oobCode != null
                ? 'Almost there! Choose a strong new password to secure your account.'
                : 'Choose a strong new password and confirm it to update your account.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 40),

          // ── New Password ──────────────────────────
          AuthTextField(
            controller: _passwordCtrl,
            label: 'New Password',
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
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter a new password';
              if (v.length < 8) return 'Minimum 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 18),

          // Password strength bar
          AnimatedBuilder(
            animation: _passwordCtrl,
            builder: (_, _) =>
                _PasswordStrengthBar(password: _passwordCtrl.text),
          ),
          const SizedBox(height: 22),

          // ── Confirm New Password ──────────────────
          AuthTextField(
            controller: _confirmCtrl,
            label: 'Confirm New Password',
            hint: '••••••••',
            prefixIcon: Icons.verified_user_outlined,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onEditingComplete: _isLoading ? null : _resetPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirm your new password';
              if (v != _passwordCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Live match indicator
          AnimatedBuilder(
            animation: _confirmCtrl,
            builder: (_, _) => _MatchChip(
              password: _passwordCtrl.text,
              confirm: _confirmCtrl.text,
            ),
          ),
          const SizedBox(height: 32),

          GradientButton(
            id: 'reset_password_submit_btn',
            onPressed: _isLoading ? null : _resetPassword,
            isLoading: _isLoading,
            label: 'Update Password',
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: 28),

          // Helper card when no valid link
          if (widget.oobCode == null && FirebaseAuth.instance.currentUser == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.35)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppColors.warning, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Use your reset link',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Open the "Reset Password" link from your email, or request a new one.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Success state ────────────────────────────────────────
  Widget _buildSuccess() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (_, t, child) =>
                Transform.scale(scale: t, child: child),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  size: 52, color: AppColors.success),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Password Updated! 🎉',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your password has been reset successfully.\nYou can now sign in with your new password.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              id: 'reset_password_done_btn',
              onPressed: () => context.go(AppRoutes.login),
              label: 'Back to Login',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Live "passwords match" chip ────────────────────────────
class _MatchChip extends StatelessWidget {
  final String password;
  final String confirm;
  const _MatchChip({required this.password, required this.confirm});

  @override
  Widget build(BuildContext context) {
    if (confirm.isEmpty) return const SizedBox.shrink();
    final matched = password == confirm;
    final color = matched ? AppColors.success : AppColors.error;
    return Align(
      alignment: Alignment.centerLeft,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Container(
          key: ValueKey(matched),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                matched
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                matched ? 'Passwords match' : 'Passwords do not match',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Password Strength Bar ──────────────────────────────────
class _PasswordStrengthBar extends StatelessWidget {
  final String password;
  const _PasswordStrengthBar({required this.password});

  int _strength() {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#\$%^&*]'))) score++;
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

    return Row(
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
    );
  }
}
