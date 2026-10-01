import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Spotify-Inspired ambient background.
/// Sleek ambient top gradient fading into the solid background color.
class PremiumBackground extends StatelessWidget {
  final Widget child;
  final bool showGrid; // Kept for backwards compatibility but not used in this sleek theme

  const PremiumBackground({
    super.key,
    required this.child,
    this.showGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        // ── Base Background ──────────────────────────────
        Container(
          color: AppColors.background,
        ),
        
        // ── Event Image Background ──────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.55,
          child: Image.asset(
            'assets/images/event_bg.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),

        // ── Ambient Gradient Overlay (Spotify Style) ──────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.55,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.background.withValues(alpha: 0.1),
                  AppColors.primaryGradient.colors[1].withValues(alpha: isDark ? 0.6 : 0.8),
                  AppColors.background,
                ],
                stops: const [0.0, 0.5, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // ── Content ──────────────────────────────────────
        child,
      ],
    );
  }
}
