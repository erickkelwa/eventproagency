import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/multia_app_bar.dart';
import '../../../core/widgets/pro_empty_state.dart';
import '../../../core/widgets/pro_section_header.dart';
import '../../../core/widgets/pro_service_card.dart';
import '../../../core/widgets/pro_skeletons.dart';
import '../providers/services_provider.dart';

class ServicesHomeScreen extends ConsumerWidget {
  const ServicesHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedServiceCategoryProvider);
    final servicesAsync = ref.watch(filteredServicesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────
          SliverToBoxAdapter(
            child: MultiaAppBar(
              title: 'Services',
              showBack: true,
            ),
          ),

          // ── Hero Header ────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book Event Services',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Professional vendors for your perfect event',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          // ── Categories Grid ───────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ProSectionHeader(
                    title: 'Browse by Category',
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 92,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: ServiceCategoryMeta.categories.length,
                      itemBuilder: (_, i) {
                        final cat = ServiceCategoryMeta.categories[i];
                        final isAll = cat == 'All';
                        final isSelected = isAll
                            ? selectedCategory == null
                            : selectedCategory == cat;
                        final color = isAll
                            ? AppColors.primary
                            : ServiceCategoryMeta.color(cat);
                        final icon = isAll
                            ? Icons.grid_view_rounded
                            : ServiceCategoryMeta.icon(cat);

                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: MultiaCategoryTile(
                            label: cat,
                            icon: icon,
                            accent: color,
                            isSelected: isSelected,
                            onTap: () => ref
                                .read(
                                    selectedServiceCategoryProvider.notifier)
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

          // ── Services List ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: ProSectionHeader(
                title: 'Available Services',
                padding: EdgeInsets.zero,
                actionLabel: servicesAsync.whenOrNull(
                  data: (list) => '${list.length} found',
                ),
              ),
            ),
          ),

          servicesAsync.when(
            loading: () => SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, _) => const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: ProServiceCardSkeleton(),
                ),
                childCount: 4,
              ),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(
                child: Text(err.toString(),
                    style:
                        TextStyle(color: AppColors.textSecondary)),
              ),
            ),
            data: (services) {
              if (services.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: ProEmptyState(
                    icon: Icons.home_repair_service_rounded,
                    title: 'No services found',
                    subtitle: 'Try a different category',
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ProServiceCard(
                        service: services[i],
                        onTap: () =>
                            context.push('/services/${services[i].id}'),
                      ),
                    ),
                    childCount: services.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }
}
