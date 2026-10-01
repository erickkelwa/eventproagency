import 'package:flutter/material.dart';

/// EventPro Design System — Spotify-Inspired with Bold Yellow→Orange→Red Gradient
/// Orange is the dominant mid-tone, yellow punches through at the top,
/// and deep red anchors the dark end for a premium, fiery look.
class AppColors {
  AppColors._();

  static bool _isDark = false;

  static void setTheme(bool isDark) {
    _isDark = isDark;
  }

  // ── Primary Palette — Peach/Orange ───────────────────
  static const Color yellow      = Color(0xFFFFCC80); 
  static const Color primary     = Color(0xFFF78B5D); // Peach/Orange accent
  static const Color primaryLight= Color(0xFFFAB193); 
  static const Color primaryDark = Color(0xFFD66030); 
  static const Color primaryGlow = Color(0x80F78B5D); 

  // ── Gradient stops ────────────────────────────────
  static const List<Color> gradientColors = [
    Color(0xFFFFC085), // light orange
    Color(0xFFF78B5D), // peach
    Color(0xFFF07441), // deeper peach
    Color(0xFFD66030), 
  ];
  static const List<double> gradientStops = [0.0, 0.30, 0.65, 1.0];

  // Dark‑mode variant: deeper, more saturated tones
  static const List<Color> gradientColorsDark = [
    Color(0xFFFF8F00), // dark amber
    Color(0xFFE65100), // deep orange
    Color(0xFFBF360C), // burnt red
    Color(0xFF6D0000), // near‑black red
  ];

  // ── Secondary Accent ───────────────────────────────────────────────────────
  static Color get secondary      => _isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1A1A1A);
  static Color get secondaryLight => _isDark ? const Color(0xFFE0E0E0) : const Color(0xFF282828);
  static Color get secondaryDark  => _isDark ? const Color(0xFFB3B3B3) : const Color(0xFF000000);
  static Color get secondaryGlow  => _isDark ? const Color(0x30FFFFFF) : const Color(0x30000000);

  // ── Tertiary ───────────────────────────────────────────────────────────────
  static const Color tertiary     = Color(0xFF535353);
  static const Color tertiaryGlow = Color(0x50535353);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success      = Color(0xFF00C853);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning      = Color(0xFFFFD600);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color error        = Color(0xFFDD2C00);
  static const Color errorLight   = Color(0xFFFFEBEE);

  // ── Backgrounds ───────────────────────────────────────────────────────────
  static Color get background          => _isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF4F0EB); // Cream background
  static Color get backgroundSecondary => _isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E4DF); // Slightly darker margins
  static Color get surface             => _isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA);
  static Color get card                => _isDark ? const Color(0xFF2B2B2B) : const Color(0xFFFFFFFF); // White cards
  static Color get cardHover           => _isDark ? const Color(0xFF383838) : const Color(0xFFF9F9F9);

  // ── Input Fields ──────────────────────────────────────────────────────────
  static Color get inputFill   => _isDark ? const Color(0xFF2B2B2B) : const Color(0xFFFFFFFF);
  static Color get border      => _isDark ? const Color(0xFF4A4A4A) : const Color(0xFFE0DCD6);
  static const Color borderFocused = Color(0xFFF78B5D);

  // ── Text ──────────────────────────────────────────────────────────────────
  static Color get textPrimary   => _isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C1C); // Dark charcoal text
  static Color get textSecondary => _isDark ? const Color(0xFFB3B3B3) : const Color(0xFF6E6E6E); // Gray muted text
  static Color get textMuted     => _isDark ? const Color(0xFF7A7A7A) : const Color(0xFF9E9E9E);

  // ── Gradients ─────────────────────────────────────────────────────────────
  /// Main brand gradient: yellow → amber → orange → deep red
  static LinearGradient get primaryGradient => LinearGradient(
    colors: _isDark ? gradientColorsDark : gradientColors,
    stops: gradientStops,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Top-to-bottom variant for app bars and backgrounds
  static LinearGradient get primaryGradientVertical => LinearGradient(
    colors: _isDark ? gradientColorsDark : gradientColors,
    stops: gradientStops,
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Orange→Red for accent stripes
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF9100), Color(0xFFDD2C00)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static LinearGradient get heroGradient => LinearGradient(
    colors: [background, background.withValues(alpha: 0)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static LinearGradient get cardGradient => LinearGradient(
    colors: [card, surface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get adminGradient => LinearGradient(
    colors: _isDark ? gradientColorsDark : gradientColors,
    stops: gradientStops,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get profileGradient => LinearGradient(
    colors: [
      _isDark ? const Color(0xFF3D2B18) : const Color(0xFFFFCC80),
      background,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static RadialGradient get glowGradient => const RadialGradient(
    colors: [Color(0x80FF6D00), Color(0x00FF6D00)],
    radius: 0.8,
  );

  // ── Category Colors ───────────────────────────────────────────────────────
  static const Color cateringColor      = Color(0xFFFFD600);
  static const Color securityColor      = Color(0xFFDD2C00);
  static const Color transportColor     = Color(0xFF2B90FF);
  static const Color gamingColor        = Color(0xFF00C853);
  static const Color entertainmentColor = Color(0xFF9046FF);
  static const Color decorColor         = Color(0xFFFF46B9);
}
