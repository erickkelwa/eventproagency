import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../../features/services/models/service_model.dart';
import 'pro_badges.dart';
import 'pro_card.dart';

/// ── Service Category Metadata ──────────────────────────────────────────────
/// Central source of truth for service category colors and icons.
class ServiceCategoryMeta {
  ServiceCategoryMeta._();

  static const List<String> categories = [
    'All',
    'Catering',
    'Photography',
    'Security',
    'Transport',
    'Decoration',
    'Entertainment',
    'Sound & Lighting',
  ];

  static Color color(String category) {
    switch (category) {
      case 'Catering':
        return AppColors.cateringColor;
      case 'Photography':
        return AppColors.decorColor;
      case 'Security':
        return AppColors.securityColor;
      case 'Transport':
        return AppColors.transportColor;
      case 'Decoration':
        return AppColors.decorColor;
      case 'Entertainment':
        return AppColors.entertainmentColor;
      case 'Sound & Lighting':
        return AppColors.transportColor;
      default:
        return AppColors.primary;
    }
  }

  static IconData icon(String category) {
    switch (category) {
      case 'Catering':
        return Icons.restaurant_rounded;
      case 'Photography':
        return Icons.camera_alt_rounded;
      case 'Security':
        return Icons.security_rounded;
      case 'Transport':
        return Icons.directions_bus_rounded;
      case 'Decoration':
        return Icons.auto_awesome_rounded;
      case 'Entertainment':
        return Icons.music_note_rounded;
      case 'Sound & Lighting':
        return Icons.speaker_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}

/// ── Pro Service Card ───────────────────────────────────────────────────────
/// Vendor service list card:
///  • glowing gradient icon tile (or image when available)
///  • tinted category badge + live availability indicator
///  • gold star rating row
///  • gradient price-range text
///  • tactile press micro-interaction
class ProServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback? onTap;

  const ProServiceCard({super.key, required this.service, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = ServiceCategoryMeta.color(service.category);
    final icon = ServiceCategoryMeta.icon(service.category);

    return ProPressable(
      onTap: onTap,
      child: ProCard(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── Icon / image tile ──────────────────────────────
              _ServiceTile(
                service: service,
                color: color,
                icon: icon,
              ),
              const SizedBox(width: 14),

              // ── Details ────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge + availability
                    Row(
                      children: [
                        Flexible(
                          child: ProBadge(
                            label: service.category,
                            color: color,
                            fontSize: 9,
                          ),
                        ),
                        const Spacer(),
                        _AvailabilityDot(isAvailable: service.isAvailable),
                      ],
                    ),
                    const SizedBox(height: 7),

                    // Name
                    Text(
                      service.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Rating
                    if (service.rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFFD700), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            service.rating!.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${service.reviewCount} reviews)',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'New on EventPro',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Price range + chevron
                    Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (b) =>
                              AppColors.primaryGradient.createShader(b),
                          child: Text(
                            service.priceRange,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 12, color: AppColors.textMuted),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ── Service Tile ───────────────────────────────────────────────────────────
/// Gradient icon tile with category glow; swaps to an image when available.
class _ServiceTile extends StatelessWidget {
  final ServiceModel service;
  final Color color;
  final IconData icon;

  const _ServiceTile({
    required this.service,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: service.imageUrl != null && service.imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: service.imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    _gradientTile(color, icon),
              )
            : _gradientTile(color, icon),
      ),
    );
  }

  Widget _gradientTile(Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.62)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Icon(icon, color: Colors.white, size: 28)),
    );
  }
}

/// ── Availability Dot ───────────────────────────────────────────────────────
/// Pulsing-style status dot + label ("Available" / "Unavailable").
class _AvailabilityDot extends StatelessWidget {
  final bool isAvailable;
  const _AvailabilityDot({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    final color = isAvailable ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 6,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isAvailable ? 'Available' : 'Unavailable',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
