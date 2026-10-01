import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    // Warm amber/orange dark backgrounds, cream warm light backgrounds
    final bg = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFFFBF5);
    final surface = isDark ? const Color(0xFF1A1208) : const Color(0xFFFFF3E0);
    final card = isDark ? const Color(0xFF251810) : const Color(0xFFFFFFFF);
    final border = isDark ? const Color(0xFF4A3020) : const Color(0xFFFFCC80);
    final textPrimary = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1A0A00);
    final textSecondary = isDark ? const Color(0xFFD4A070) : const Color(0xFF6D3A00);
    final textMuted = isDark ? const Color(0xFF7A5540) : const Color(0xFF9E6B35);
    final inputFill = isDark ? const Color(0xFF2A1A0E) : const Color(0xFFFFF3E0);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,       // FF6D00 bold orange
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryDark, // DD2C00 deep red
        onPrimaryContainer: Colors.white,
        secondary: AppColors.yellow,       // FFD600 yellow accent
        onSecondary: const Color(0xFF1A0A00),
        tertiary: AppColors.primaryLight,  // FF9100 amber
        onTertiary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
      ),
      textTheme: _buildTextTheme(textPrimary, textSecondary, textMuted),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.outfit(
          color: textMuted,
          fontSize: 15,
        ),
        labelStyle: GoogleFonts.outfit(
          color: textSecondary,
          fontSize: 15,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          // Background is transparent so gradient ShaderMask can shine through
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.primaryDark.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50), // Spotify pill shape
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: card,
        contentTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        // Spotify-style: near-black bar with glowing accent indicator
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFF1A0A00),
        selectedItemColor: AppColors.yellow,      // Yellow highlight for selection
        unselectedItemColor: isDark ? const Color(0xFF7A5540) : const Color(0xFFD4A070),
        selectedLabelStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w400),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFF1A0A00),
        indicatorColor: AppColors.primary.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(
              color: AppColors.yellow,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            );
          }
          return GoogleFonts.outfit(
            color: textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.yellow, size: 24);
          }
          return IconThemeData(color: textMuted, size: 22);
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,  // Bold orange FAB
        foregroundColor: Colors.white,
        elevation: 8,
        splashColor: Color(0x40FFD600),  // Yellow ripple on press
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: border),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color textPrimary, Color textSecondary, Color textMuted) {
    return TextTheme(
      displayLarge: GoogleFonts.outfit(
        fontSize: 57, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -1.5,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 45, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.outfit(
        fontSize: 36, fontWeight: FontWeight.w700, color: textPrimary,
      ),
      headlineLarge: GoogleFonts.outfit(
        fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 28, fontWeight: FontWeight.w600, color: textPrimary,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontSize: 24, fontWeight: FontWeight.w600, color: textPrimary,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.outfit(
        fontSize: 14, fontWeight: FontWeight.w600, color: textSecondary, letterSpacing: 0.1,
      ),
      bodyLarge: GoogleFonts.outfit(
        fontSize: 16, fontWeight: FontWeight.w400, color: textSecondary,
      ),
      bodyMedium: GoogleFonts.outfit(
        fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary,
      ),
      bodySmall: GoogleFonts.outfit(
        fontSize: 12, fontWeight: FontWeight.w400, color: textMuted,
      ),
      labelLarge: GoogleFonts.outfit(
        fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.outfit(
        fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary,
      ),
      labelSmall: GoogleFonts.outfit(
        fontSize: 11, fontWeight: FontWeight.w500, color: textMuted, letterSpacing: 0.5,
      ),
    );
  }
}
