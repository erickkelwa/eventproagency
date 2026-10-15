import 'dart:math' as math;
import 'dart:async';
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
import '../../../core/widgets/scroll_reveal.dart';
import '../providers/events_provider.dart';
import '../models/event_model.dart';
import '../widgets/notifications_modal.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../../../core/widgets/app_side_drawer.dart';
import '../../../core/localization/language_provider.dart';
import '../../auth/providers/auth_provider.dart';

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

// ── Sliding Banner Images ──────────────────────────────────────────────────
const _sliderImages = [
  'https://images.unsplash.com/photo-1540039155732-6762b5134fb3?q=80&w=1200&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?q=80&w=1200&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1505373877841-8d25f7d46678?q=80&w=1200&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1452626038306-9aae5e071dd3?q=80&w=1200&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?q=80&w=1200&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1460661419291-866e9845b612?q=80&w=1200&auto=format&fit=crop',
];
const _sliderLabels = [
  'Live Music Events',
  'Festivals & Culture',
  'Tech & Innovation',
  'Sports & Adventure',
  'Food & Gourmet',
  'Art & Exhibitions',
];

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _orbCtrl;
  late final PageController _sliderCtrl;
  int _sliderIndex = 0;
  Timer? _sliderTimer;
  String _selectedCity = 'Nairobi, Kenya';

  final List<Map<String, String>> _kenyaLocations = const [
    {'city': 'Nairobi, Kenya', 'desc': 'Capital, Westlands & Kilimani'},
    {'city': 'Mombasa, Kenya', 'desc': 'Nyali, Diani & Coastal Events'},
    {'city': 'Kisumu, Kenya', 'desc': 'Lakeside & Mega Concerts'},
    {'city': 'Nakuru, Kenya', 'desc': 'Rift Valley & Festivals'},
    {'city': 'Eldoret, Kenya', 'desc': 'Highlands & Sports Events'},
  ];

  void _showLocationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Select Event Location (Kenya)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ..._kenyaLocations.map((loc) {
                final isSelected = loc['city'] == _selectedCity;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.place_rounded,
                      color: isSelected ? AppColors.primary : AppColors.textMuted,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    loc['city']!,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    loc['desc']!,
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _selectedCity = loc['city']!);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _sliderCtrl = PageController(viewportFraction: 0.92);
    _sliderTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final next = (_sliderIndex + 1) % _sliderImages.length;
      _sliderCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _sliderCtrl.dispose();
    _sliderTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final eventsAsync = ref.watch(filteredEventsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppSideDrawer(),
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
                // ── Fasta Event Header & Kenya Location Selector ────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                    child: Row(
                      children: [
                        Builder(
                          builder: (ctx) => IconButton(
                            onPressed: () => Scaffold.of(ctx).openDrawer(),
                            icon: Icon(
                              Icons.menu_rounded,
                              color: AppColors.textPrimary,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Location chip
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _showLocationPicker(context),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.location_on_rounded, color: AppColors.primary, size: 14),
                                    SizedBox(width: 3),
                                    Text(
                                      'LOCATION',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 1),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _selectedCity,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textSecondary),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Language Toggle
                        Consumer(
                          builder: (context, ref, _) {
                            final currentLang = ref.watch(languageProvider);
                            return InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                final next = currentLang == AppLanguage.en
                                    ? AppLanguage.sw
                                    : (currentLang == AppLanguage.sw
                                        ? AppLanguage.fr
                                        : AppLanguage.en);
                                ref.read(languageProvider.notifier).state = next;
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  '${currentLang.flag} ${currentLang.code}',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        // Quick Passes / Bookings shortcut
                        IconButton(
                          tooltip: 'My Passes & Bookings',
                          onPressed: () => context.go(AppRoutes.myBookings),
                          icon: Stack(
                            children: [
                              Icon(Icons.confirmation_number_outlined, color: AppColors.textSecondary, size: 22),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Notification Bell with reactive unread badge
                        Stack(
                          children: [
                            IconButton(
                              onPressed: () => NotificationsModal.show(context),
                              icon: Icon(Icons.notifications_outlined, color: AppColors.textSecondary, size: 22),
                            ),
                            Consumer(
                              builder: (context, ref, _) {
                                final unread = ref.watch(notificationsProvider).where((n) => !n.isRead).isNotEmpty;
                                if (!unread) return const SizedBox.shrink();
                                return Positioned(
                                  right: 12,
                                  top: 12,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryDark,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.background, width: 1.5),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Fasta Pass Flash Offer Banner ───────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                    child: Consumer(
                      builder: (context, ref, _) {
                        final user = ref.watch(authStateProvider).valueOrNull?.user;
                        final firstName = user != null && user.name.isNotEmpty
                            ? user.name.split(' ').first
                            : 'Friend';

                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1A1A1A), Color(0xFF2D1600)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        '⚡ FASTA PASS',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Instant Access, Karibu $firstName!',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Instant digital tickets, VIP passes & verified event agency services.',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.45),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.bolt_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // ── Search Bar ─────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: RevealOnce.up(
                      delay: const Duration(milliseconds: 100),
                      child: _SearchBar(
                        onTap: () => context.push(AppRoutes.search),
                      ),
                    ),
                  ),
                ),

                // ── Sliding Photo Banner ──────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 185,
                          child: PageView.builder(
                            controller: _sliderCtrl,
                            itemCount: _sliderImages.length,
                            onPageChanged: (i) => setState(() => _sliderIndex = i),
                            itemBuilder: (context, i) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: _sliderImages[i],
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                          color: AppColors.card,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (_, __, ___) => Container(
                                          color: AppColors.card,
                                        ),
                                      ),
                                      // gradient overlay
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withValues(alpha: 0.72),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // label
                                      Positioned(
                                        bottom: 14,
                                        left: 16,
                                        right: 16,
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.92),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                _sliderLabels[i],
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.4,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Dot indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_sliderImages.length, (i) {
                            final active = i == _sliderIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: active ? 22 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.primary
                                    : AppColors.primary.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                      ],
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
                        const RevealOnce.fromLeft(
                          delay: Duration(milliseconds: 150),
                          child: ProSectionHeader(
                            title: 'Popular categories',
                            padding: EdgeInsets.zero,
                          ),
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

                // ── Nearby Events Map Card ────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: GestureDetector(
                      onTap: () => context.push('/events/map'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.map_rounded,
                                color: Color(0xFF38BDF8),
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Nearby Events Map',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(Icons.bolt_rounded, color: Color(0xFFFBBF24), size: 16),
                                    ],
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Discover venues, distances & live GPS locations',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Explore',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
                            const RevealOnce.fromLeft(
                              child: ProSectionHeader(
                                title: 'Featured',
                                padding: EdgeInsets.zero,
                              ),
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
                                  child: RevealOnce.up(
                                    delay: Duration(milliseconds: 80 + i * 100),
                                    child: _HeroBanner(event: banners[i]),
                                  ),
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
                    child: RevealOnce.fromLeft(
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
                            // ✨ Partiful-style pop-in: each card reveals with
                            // a staggered delay as you scroll down.
                            child: ScrollReveal(
                              key: ValueKey('event_card_$i'),
                              index: i,
                              staggerMs: 60,
                              durationMs: 480,
                              child: ProEventCard(
                                event: events[i],
                                onTap: () =>
                                    context.push('/events/${events[i].id}'),
                              ),
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
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.search_rounded,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search events, concerts, VIP passes & services...',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
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
              color: catColor.withValues(alpha: 0.25),
              blurRadius: 26,
              offset: const Offset(0, 12),
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
                      placeholder: (_, _a) => _GradientFallback(category: event.category),
                      errorWidget: (_, _a, _b) => _GradientFallback(category: event.category),
                    )
                  : _GradientFallback(category: event.category),

              // Multi-layered cinema gradient
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x33000000),
                      Colors.transparent,
                      Color(0xD9000000),
                      Color(0xFA000000),
                    ],
                    stops: [0.0, 0.25, 0.70, 1.0],
                  ),
                ),
              ),

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
