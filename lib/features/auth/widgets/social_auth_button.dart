import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Premium social auth button — navy card with subtle hover scale.
class SocialAuthButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? assetPath;
  final String label;
  final Color? iconColor;
  final String? id;

  const SocialAuthButton({
    super.key,
    required this.onPressed,
    this.icon,
    this.assetPath,
    required this.label,
    this.iconColor,
    this.id,
  });

  @override
  State<SocialAuthButton> createState() => _SocialAuthButtonState();
}

class _SocialAuthButtonState extends State<SocialAuthButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
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
      onTapDown: widget.onPressed == null ? null : (_) => _ctrl.forward(),
      onTapUp: widget.onPressed == null ? null : (_) => _ctrl.reverse(),
      onTapCancel: widget.onPressed == null ? null : () => _ctrl.reverse(),
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          key: widget.id != null ? Key(widget.id!) : null,
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Google "G" icon — rendered as a styled container
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: widget.icon != null
                      ? Icon(widget.icon,
                          color: widget.iconColor ?? AppColors.secondary,
                          size: 22)
                      : Text(
                          'G',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: widget.iconColor ?? const Color(0xFF4285F4),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}