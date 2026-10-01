import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/multia_app_bar.dart';
import '../../../core/widgets/pro_badges.dart';
import '../../../core/widgets/pro_empty_state.dart';
import '../../../core/widgets/pro_event_card.dart';
import '../../../core/widgets/pro_section_header.dart';
import '../../../core/widgets/pro_skeletons.dart';
import '../providers/events_provider.dart';
import '../models/event_model.dart';
import '../../../core/theme/theme_provider.dart';

/// Support WhatsApp number
const _supportWhatsApp = '254728664792';

const _categories = [
  ('All', Icons.grid_view_rounded),
  ('Music', Icons.music_note_rounded),
  ('Conference', Icons.groups_rounded),
  ('Sports', Icons.sports_rounded),
  ('Comedy', Icons.sentiment_very_satisfied_rounded),
  ('Art', Icons.palette_rounded),
  ('Food', Icons.restaurant_rounded),
  ('Tech', Icons.computer_rounded),
];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbCtrl;

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final eventsAsync = ref.watch(filteredEventsProvider);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _WhatsAppFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(
        children: [
          // ── Ambient Background Orbs ──────────────────────
          AnimatedBuilder(
            animation: _orbCtrl,
            builder: (_, _) {
              final t = _orbCtrl.value;
              return Stack(
                children: [
                  Positioned(
                    top: -80 + (math.sin(t * math.pi) * 20),
                    right: -60,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          AppColors.primary.withValues(alpha: 0.10),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 320 + (t * 40),
                    left: -80,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          AppColors.secondary.withValues(alpha: 0.07),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // ── Main Scroll ──────────────────────────────────
          RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.card,
            onRefresh: () => ref.read(eventsProvider.notifier).refresh(),
            child: CustomScrollView(
              slivers: [
                // ── Top Bar ────────────────────────────────
                SliverToBoxAdapter(
                  child: MultiaAppBar(
                    title: 'EventPro',
                    leading: IconButton(
                      onPressed: () =>
                          ref.read(themeProvider.notifier).toggleTheme(),
                      icon: Icon(
                        isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                    trailing: Stack(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.notifications_outlined,
                              color: AppColors.textSecondary, size: 22),
                        ),
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.background, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Search Bar ─────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: _SearchBar(
                      onTap: () => context.push(AppRoutes.search),
                    ),
                  ),
                ),

                // ── Category Tiles ─────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 0, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ProSectionHeader(
                          title: 'Popular categories',
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 92,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            itemBuilder: (_, i) {
                              final (cat, icon) = _categories[i];
                              final isAll = cat == 'All';
                              final isSelected = isAll
                                  ? selectedCategory == null
                                  : selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: MultiaCategoryTile(
                                  label: cat,
                                  icon: icon,
                                  isSelected: isSelected,
                                  onTap: () => ref
                                      .read(selectedCategoryProvider.notifier)
                                      .state = isAll ? null : cat,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Featured Hero Banners ──────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 26, 0, 0),
                    child: eventsAsync.when(
                      data: (events) {
                        final featured = events
                            .where((e) => e.isFeatured)
                            .toList();
                        final banners =
                            featured.isNotEmpty ? featured : events.take(2).toList();
                        if (banners.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const ProSectionHeader(
                              title: 'Featured',
                              padding: EdgeInsets.zero,
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 180,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.only(left: 20),
                                itemCount: banners.length,
                                itemBuilder: (_, i) => Padding(
                                  padding: const EdgeInsets.only(right: 14),
                                  child: _HeroBanner(event: banners[i]),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(left: 20),
                          itemCount: 2,
                          itemBuilder: (_, _) => const Padding(
                            padding: EdgeInsets.only(right: 14),
                            child: ProFeaturedSkeleton(),
                          ),
                        ),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),

                // ── Events List Header ─────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 28, 0, 0),
                    child: eventsAsync.whenOrNull(
                          data: (events) => ProSectionHeader(
                            title: 'Upcoming events',
                            actionLabel: '${events.length} found',
                            padding: EdgeInsets.zero,
                          ),
                        ) ??
                        const ProSectionHeader(
                          title: 'Upcoming events',
                          padding: EdgeInsets.zero,
                        ),
                  ),
                ),

                // ── Events List ────────────────────────────
                eventsAsync.when(
                  data: (events) {
                    if (events.isEmpty) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: ProEmptyState(
                          icon: Icons.event_busy_rounded,
                          title: 'No events found',
                          subtitle:
                              'Try a different category or check back later',
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: ProEventCard(
                              event: events[i],
                              onTap: () =>
                                  context.push('/events/${events[i].id}'),
                            ),
                          ),
                          childCount: events.length,
                        ),
                      ),
                    );
                  },
                  loading: () => SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, _) => const Padding(
                        padding: EdgeInsets.fromLTRB(20, 14, 20, 14),
                        child: ProEventCardSkeleton(),
                      ),
                      childCount: 4,
                    ),
                  ),
                  error: (err, _) => SliverFillRemaining(
                    child: Center(
                      child: Text(err.toString(),
                          style: const TextStyle(color: AppColors.error)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

// ── Search Bar ─────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
            const SizedBox(width: 10),
            Text(
              'Search events, venues...',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Featured Hero Banner ───────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final EventModel event;

  const _HeroBanner({required this.event});

  @override
  Widget build(BuildContext context) {
    final catColor = EventCategoryMeta.color(event.category);
    final width = MediaQuery.of(context).size.width - 40;

    return GestureDetector(
      onTap: () => context.push('/events/${event.id}'),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: catColor.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              event.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: event.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          _GradientFallback(category: event.category),
                    )
                  : _GradientFallback(category: event.category),

              // Bottom scrim for legibility
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xE6000000)],
                    stops: [0.35, 1.0],
                  ),
                ),
              ),

              // Glass date chip
              Positioned(
                top: 14,
                right: 14,
                child: ProGlassDateChip(date: event.date, accent: catColor),
              ),

              // Content
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ProBadge(
                        label: event.category,
                        color: catColor,
                        glass: true,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 12, color: Colors.white60),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.venue,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              event.formattedPrice,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
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
      ),
    );
  }
}

// ── Premium Image Fallback ─────────────────────────────────────
class _GradientFallback extends StatelessWidget {
  final String category;

  const _GradientFallback({required this.category});

  @override
  Widget build(BuildContext context) {
    String assetPath;
    switch (category.toLowerCase()) {
      case 'music':
        assetPath = 'assets/images/music.jpg';
        break;
      case 'tech':
      case 'conference':
        assetPath = 'assets/images/tech.jpg';
        break;
      case 'food':
        assetPath = 'assets/images/food.jpg';
        break;
      case 'comedy':
      case 'art':
      case 'theater':
        assetPath = 'assets/images/comedy.jpg';
        break;
      default:
        assetPath = 'assets/images/music.jpg';
    }

    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFF1A1A2E),
          child: const Center(
            child: Icon(Icons.event_rounded, color: Colors.white54, size: 36),
          ),
        );
      },
    );
  }
}

// ── WhatsApp FAB ───────────────────────────────────────────────
class _WhatsAppFAB extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () async {
          final url = Uri.parse('https://wa.me/$_supportWhatsApp');
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.chat_bubble_rounded, color: Colors.black),
      ),
    );
  }
}
