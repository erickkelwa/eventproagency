import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

/// ── Event Category Metadata ────────────────────────────────────────────────
/// Central source of truth for category colors, icons and fallback imagery.
class EventCategoryMeta {
  EventCategoryMeta._();

  static Color color(String category) {
    switch (category.toLowerCase().trim()) {
      case 'music':
        return AppColors.entertainmentColor;
      case 'food':
        return AppColors.cateringColor;
      case 'sports':
        return AppColors.success;
      case 'tech':
      case 'conference':
        return AppColors.transportColor;
      case 'art':
        return AppColors.decorColor;
      case 'comedy':
        return AppColors.entertainmentColor;
      default:
        return AppColors.primary;
    }
  }

  static IconData icon(String category) {
    switch (category.toLowerCase().trim()) {
      case 'music':
        return Icons.music_note_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'sports':
        return Icons.sports_rounded;
      case 'tech':
        return Icons.computer_rounded;
      case 'conference':
        return Icons.groups_rounded;
      case 'art':
        return Icons.palette_rounded;
      case 'comedy':
        return Icons.sentiment_very_satisfied_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  /// Bundled asset used when an event has no (or a broken) network image.
  static String assetImage(String category) {
    switch (category.toLowerCase().trim()) {
      case 'tech':
      case 'conference':
        return 'assets/images/tech.jpg';
      case 'food':
        return 'assets/images/food.jpg';
      case 'comedy':
      case 'art':
      case 'theater':
        return 'assets/images/comedy.jpg';
      case 'music':
      case 'sports':
      default:
        return 'assets/images/music.jpg';
    }
  }
}

/// ── Pro Badge ──────────────────────────────────────────────────────────────
/// Pill badge in two flavors: tinted (on surfaces) and glass (over imagery).
class ProBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  /// Frosted-glass style for use over images — white text, backdrop blur.
  final bool glass;
  final double fontSize;
  final double borderRadius;

  const ProBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.glass = false,
    this.fontSize = 10,
    this.borderRadius = 7,
  });

  @override
  Widget build(BuildContext context) {
    if (glass) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: fontSize + 2, color: Colors.white),
                  const SizedBox(width: 4),
                ],
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// ── Status Badge ───────────────────────────────────────────────────────────
/// Booking status chip with semantic colors and icons.
class ProStatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const ProStatusBadge({super.key, required this.status, this.fontSize = 10});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status.toLowerCase()) {
      'confirmed' => (
          'Confirmed',
          AppColors.primary,
          Icons.check_circle_rounded,
        ),
      'attended' => (
          'Attended',
          AppColors.success,
          Icons.done_all_rounded,
        ),
      'cancelled' => (
          'Cancelled',
          AppColors.error,
          Icons.cancel_rounded,
        ),
      _ => (
          'Pending',
          AppColors.warning,
          Icons.pending_rounded,
        ),
    };

    return ProBadge(
      label: label,
      color: color,
      icon: icon,
      fontSize: fontSize,
      borderRadius: 20,
    );
  }
}

/// ── Availability Pill ──────────────────────────────────────────────────────
/// Shows remaining capacity with escalating urgency (green → amber → red).
class ProAvailabilityPill extends StatelessWidget {
  final int availableSlots;
  final int capacity;

  const ProAvailabilityPill({
    super.key,
    required this.availableSlots,
    required this.capacity,
  });

  @override
  Widget build(BuildContext context) {
    if (availableSlots <= 0) {
      return const ProBadge(
        label: 'Sold Out',
        color: AppColors.error,
        icon: Icons.block_rounded,
        borderRadius: 20,
      );
    }

    final scarce = capacity > 0 && availableSlots <= capacity * 0.15;
    if (scarce) {
      return ProBadge(
        label: 'Only $availableSlots left',
        color: AppColors.warning,
        icon: Icons.local_fire_department_rounded,
        borderRadius: 20,
      );
    }

    return ProBadge(
      label: '$availableSlots left',
      color: AppColors.success,
      icon: Icons.event_seat_rounded,
      borderRadius: 20,
    );
  }
}

/// ── Glass Date Chip ────────────────────────────────────────────────────────────────
/// Frosted chip showing "24 SEP" — designed to sit over event imagery.
class ProGlassDateChip extends StatelessWidget {
  final DateTime date;
  final Color accent;

  const ProGlassDateChip({
    super.key,
    required this.date,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('d').format(date),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM').format(date).toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  letterSpacing: 0.6,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
