import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GradientElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final double borderRadius;
  final String? id;

  const GradientElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
    this.width,
    this.height,
    this.borderRadius = 50.0,
    this.id,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: isDisabled
            ? null
            : AppColors.primaryGradient,
        color: isDisabled ? Theme.of(context).disabledColor.withValues(alpha: 0.12) : null,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isDisabled
            ? []
            : [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: DefaultTextStyle.merge(
              style: TextStyle(
                color: isDisabled
                    ? Theme.of(context).disabledColor
                    : Colors.white,
                fontWeight: FontWeight.w700,
              ),
              child: Center(
                widthFactor: 1.0,
                heightFactor: 1.0,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
