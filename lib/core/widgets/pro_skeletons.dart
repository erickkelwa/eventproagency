import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

/// ── Pro Skeletons ──────────────────────────────────────────────────────────
/// Structured loading placeholders that mirror the real card layouts.
/// Blocks are separated by transparent gaps so the layout reads clearly
/// while the whole group shimmers together.

Widget _shimmer({required Widget child}) {
  return Shimmer.fromColors(
    baseColor: AppColors.card,
    highlightColor: AppColors.cardHover,
    child: child,
  );
}

BoxDecoration _block({double radius = 8}) => BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(radius),
    );

/// Skeleton matching [ProEventCard] (image block + text lines + price row).
class ProEventCardSkeleton extends StatelessWidget {
  const ProEventCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmer(
      child: SizedBox(
        height: 124,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image block
            Container(width: 116, decoration: _block(radius: 20)),
            const SizedBox(width: 14),
            // Text lines
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                          width: 64, height: 18, decoration: _block(radius: 7)),
                      const SizedBox(width: 8),
                      Container(
                          width: 52, height: 18, decoration: _block(radius: 7)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(width: 190, height: 16, decoration: _block()),
                  const SizedBox(height: 10),
                  Container(width: 130, height: 16, decoration: _block()),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                          width: 72, height: 20, decoration: _block(radius: 20)),
                      const Spacer(),
                      Container(
                          width: 58, height: 20, decoration: _block(radius: 20)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton matching the featured banner carousel card.
class ProFeaturedSkeleton extends StatelessWidget {
  const ProFeaturedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmer(
      child: Container(
        width: 260,
        height: 220,
        decoration: _block(radius: 22),
      ),
    );
  }
}

/// Skeleton matching [ProServiceCard] (icon tile + text lines).
class ProServiceCardSkeleton extends StatelessWidget {
  const ProServiceCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmer(
      child: SizedBox(
        height: 100,
        child: Row(
          children: [
            Container(
                width: 64, height: 64, decoration: _block(radius: 18)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                          width: 70, height: 16, decoration: _block(radius: 7)),
                      const Spacer(),
                      Container(
                          width: 60, height: 14, decoration: _block(radius: 20)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(width: 160, height: 16, decoration: _block()),
                  const SizedBox(height: 10),
                  Container(width: 110, height: 14, decoration: _block()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton matching [ProBookingCard] (hero image + details + ticket stub).
class ProBookingCardSkeleton extends StatelessWidget {
  const ProBookingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image block
          Container(
            height: 140,
            width: double.infinity,
            decoration: _block(radius: 22),
          ),
          const SizedBox(height: 18),
          // Detail lines
          Container(width: 200, height: 14, decoration: _block()),
          const SizedBox(height: 12),
          Container(width: 150, height: 14, decoration: _block()),
          const SizedBox(height: 18),
          // Ticket stub
          Container(
            height: 56,
            width: double.infinity,
            decoration: _block(radius: 14),
          ),
        ],
      ),
    );
  }
}
