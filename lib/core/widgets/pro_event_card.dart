import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../../features/events/models/event_model.dart';
import 'pro_badges.dart';
import 'pro_card.dart';

/// ── Pro Event Card ─────────────────────────────────────────────────────────
/// Flagship list card for events:
///  • image (or category asset fallback) with frosted-glass date chip
///  • tinted category badge + gold "Featured" badge
///  • gradient price text + availability pill with urgency states
///  • gradient border + brand glow on featured events
///  • tactile press micro-interaction
class ProEventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;

  const ProEventCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final catColor = EventCategoryMeta.color(event.category);

    return ProPressable(
      onTap: onTap,
      child: ProCard(
        gradientBorder: event.isFeatured,
        glowColor: event.isFeatured ? AppColors.primary : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image with glass date chip ───────────────────────
            SizedBox(
              width: 116,
              height: 128,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(19),
                      bottomLeft: Radius.circular(19),
                    ),
                    child: _EventImage(event: event, catColor: catColor),
                  ),
                  // Bottom scrim so the date chip always reads
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x66000000)],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: ProGlassDateChip(date: event.date, accent: catColor),
                  ),
                ],
              ),
            ),

            // ── Info column ──────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges
                    Row(
                      children: [
                        Flexible(
                          child: ProBadge(
                            label: event.category,
                            color: catColor,
                          ),
                        ),
                        if (event.isFeatured) ...[
                          const SizedBox(width: 6),
                          const _FeaturedBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 7),

                    // Title
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 7),

                    // Venue
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 12, color: catColor.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.venue,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),

                    // Price + availability
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Gradient price
                        ShaderMask(
                          shaderCallback: (b) =>
                              AppColors.primaryGradient.createShader(b),
                          child: Text(
                            event.formattedPrice,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const Spacer(),
                        ProAvailabilityPill(
                          availableSlots: event.availableSlots,
                          capacity: event.capacity,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ── Featured Badge ─────────────────────────────────────────────────────────
/// Compact gradient badge with star icon.
class _FeaturedBadge extends StatelessWidget {
  const _FeaturedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Colors.black, size: 10),
          SizedBox(width: 3),
          Text(
            'FEATURED',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// ── Event Image with fallback chain ────────────────────────────────────────
/// Network image → bundled category asset → category icon tile.
class _EventImage extends StatelessWidget {
  final EventModel event;
  final Color catColor;

  const _EventImage({required this.event, required this.catColor});

  @override
  Widget build(BuildContext context) {
    if (event.imageUrl != null && event.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: event.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _IconFallback(catColor: catColor),
        errorWidget: (context, url, error) =>
            _AssetFallback(category: event.category),
      );
    }
    return _AssetFallback(category: event.category);
  }
}

class _AssetFallback extends StatelessWidget {
  final String category;
  const _AssetFallback({required this.category});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      EventCategoryMeta.assetImage(category),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _IconFallback(
        catColor: EventCategoryMeta.color(category),
      ),
    );
  }
}

class _IconFallback extends StatelessWidget {
  final Color catColor;
  const _IconFallback({required this.catColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: Icon(Icons.event_rounded, color: catColor, size: 32),
      ),
    );
  }
}
