import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// ── Pro Pressable ──────────────────────────────────────────────────────────
/// Wraps any widget with a tactile press micro-interaction:
/// scales down subtly on touch + light haptic tick.
class ProPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final bool haptic;

  const ProPressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
    this.haptic = true,
  });

  @override
  State<ProPressable> createState() => _ProPressableState();
}

class _ProPressableState extends State<ProPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.pressedScale).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        _ctrl.forward();
        if (widget.haptic) HapticFeedback.selectionClick();
      },
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

/// ── Pro Card ───────────────────────────────────────────────────────────────
/// Base card surface for the design system:
///  • layered depth shadow (ambient + optional brand glow)
///  • optional 1.2px gradient border (premium flag)
///  • consistent corner radii across the app
class ProCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final bool gradientBorder;
  final Color? glowColor;
  final EdgeInsetsGeometry? margin;

  const ProCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.gradientBorder = false,
    this.glowColor,
    this.margin,
  });

  List<BoxShadow> get _shadows => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.16),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
        if (glowColor != null)
          BoxShadow(
            color: glowColor!.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
      ];

  @override
  Widget build(BuildContext context) {
    Widget card;
    if (gradientBorder) {
      card = Container(
        margin: margin,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: _shadows,
        ),
        child: Container(
          margin: const EdgeInsets.all(1.2),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(borderRadius - 1.2),
          ),
          child: child,
        ),
      );
    } else {
      card = Container(
        margin: margin,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(borderRadius),
          border:
              Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          boxShadow: _shadows,
        ),
        child: child,
      );
    }
    return card;
  }
}
