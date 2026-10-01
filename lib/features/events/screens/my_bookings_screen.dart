import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/pro_booking_card.dart';
import '../../../core/widgets/pro_empty_state.dart';
import '../../../core/widgets/pro_skeletons.dart';
import '../providers/bookings_provider.dart';
import '../models/booking_model.dart';

const _tabs = ['All', 'Upcoming', 'Attended', 'Cancelled'];

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── Sliver App Bar ──────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(Icons.arrow_back_rounded,
                      color: AppColors.textPrimary, size: 20),
                ),
              ),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'My Tickets',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                ShaderMask(
                  shaderCallback: (b) =>
                      AppColors.primaryGradient.createShader(b),
                  child: const Text(
                    '.',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 0.9,
                    ),
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: _SegmentedTabs(controller: _tabController),
            ),
          ),
        ],
        body: bookingsAsync.when(
          data: (allBookings) {
            return TabBarView(
              controller: _tabController,
              children: [
                _BookingList(
                  bookings: allBookings,
                  onRefresh: () => ref.read(bookingsProvider.notifier).refresh(),
                ),
                _BookingList(
                  bookings: allBookings
                      .where((b) => b.isUpcoming)
                      .toList(),
                  onRefresh: () => ref.read(bookingsProvider.notifier).refresh(),
                  emptyLabel: 'No upcoming events',
                  emptySubtitle: 'Browse events and book your next experience',
                  emptyIcon: Icons.rocket_launch_rounded,
                  onBrowse: () => context.go(AppRoutes.home),
                ),
                _BookingList(
                  bookings: allBookings
                      .where((b) => b.status == 'attended')
                      .toList(),
                  onRefresh: () => ref.read(bookingsProvider.notifier).refresh(),
                  emptyLabel: 'No events attended yet',
                  emptySubtitle: 'Your event history will appear here',
                  emptyIcon: Icons.theater_comedy_rounded,
                ),
                _BookingList(
                  bookings: allBookings
                      .where((b) => b.isCancelled)
                      .toList(),
                  onRefresh: () => ref.read(bookingsProvider.notifier).refresh(),
                  emptyLabel: 'No cancellations',
                  emptySubtitle: 'Your cancelled bookings will appear here',
                  emptyIcon: Icons.task_alt_rounded,
                ),
              ],
            );
          },
          loading: () => ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            itemCount: 4,
            itemBuilder: (_, _) => const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: ProBookingCardSkeleton(),
            ),
          ),
          error: (e, _) => Center(
            child: Text(e.toString(),
                style: const TextStyle(color: AppColors.error)),
          ),
        ),
      ),

      // ── Bottom Nav ────────────────────────────────────────────
      bottomNavigationBar: AppBottomNav(currentIndex: 3),
    );
  }
}

// ── Gold Tab Bar ────────────────────────────────────────────────────────────
class _SegmentedTabs extends StatelessWidget {
  final TabController controller;
  const _SegmentedTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.border.withValues(alpha: 0.6)),
        ),
        child: TabBar(
          controller: controller,
          dividerHeight: 0,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(11),
          ),
          labelColor: Colors.black,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          tabs: _tabs.map((t) => Tab(height: 36, text: t)).toList(),
        ),
      ),
    );
  }
}

// ── Booking List ────────────────────────────────────────────────────────────
class _BookingList extends StatelessWidget {
  final List<BookingModel> bookings;
  final Future<void> Function() onRefresh;
  final String emptyLabel;
  final String emptySubtitle;
  final IconData emptyIcon;
  final VoidCallback? onBrowse;

  const _BookingList({
    required this.bookings,
    required this.onRefresh,
    this.emptyLabel = 'No bookings',
    this.emptySubtitle = '',
    this.emptyIcon = Icons.confirmation_number_rounded,
    this.onBrowse,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return ProEmptyState(
        icon: emptyIcon,
        title: emptyLabel,
        subtitle: emptySubtitle,
        actionLabel: onBrowse != null ? 'Browse Events' : null,
        onAction: onBrowse,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        itemCount: bookings.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ProBookingCard(booking: bookings[i]),
        ),
      ),
    );
  }
}

