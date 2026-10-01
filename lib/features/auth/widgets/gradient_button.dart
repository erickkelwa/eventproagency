import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Premium gold gradient CTA button with press animation and glow.
class GradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;
  final String? id;
  final List<Color>? gradientColors;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.id,
    this.gradientColors,
    this.icon,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
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
    final colors = widget.gradientColors ?? AppColors.gradientColors;

    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => _ctrl.forward(),
      onTapUp: isDisabled ? null : (_) => _ctrl.reverse(),
      onTapCancel: isDisabled ? null : () => _ctrl.reverse(),
      onTap: isDisabled ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: isDisabled
                  ? null
                  : LinearGradient(
                      colors: colors,
                      stops: widget.gradientColors == null ? AppColors.gradientStops : null,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
              color: isDisabled ? AppColors.border : null,
              borderRadius: BorderRadius.circular(50), // pill shape
              boxShadow: isDisabled
                  ? null
                  : [
                      BoxShadow(
                        color: colors.last.withValues(alpha: 0.45),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                        spreadRadius: -4,
                      ),
                    ],
            ),
            child: Center(
              key: widget.id != null ? Key(widget.id!) : null,
              child: widget.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon,
                              color: isDisabled ? AppColors.textMuted : Colors.white,
                              size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDisabled ? AppColors.textMuted : Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
