import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Multia-style top application bar.
///
/// A centered wordmark with a gradient period, flanked by equal-width
/// leading / trailing slots so the title stays optically centered.
class MultiaAppBar extends StatelessWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final bool showBack;
  final VoidCallback? onBack;

  const MultiaAppBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.showBack = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final Widget left = showBack
        ? IconButton(
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back_rounded,
                color: AppColors.textSecondary, size: 22),
          )
        : (leading ?? const SizedBox(width: 48));

    final Widget right = trailing ?? const SizedBox(width: 48);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            left,
            Expanded(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
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
                        '.',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 0.9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            right,
          ],
        ),
      ),
    );
  }
}

/// Multia-style rounded-square category tile: an icon in a soft tile
/// with the label beneath. Works for any accent color.
class MultiaCategoryTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accent;

  const MultiaCategoryTile({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.accent = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 82,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? accent.withValues(alpha: 0.6)
                : AppColors.border.withValues(alpha: 0.6),
            width: isSelected ? 1.4 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? accent.withValues(alpha: 0.18)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? accent : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
