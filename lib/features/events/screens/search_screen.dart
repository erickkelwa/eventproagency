import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pro_empty_state.dart';
import '../../../core/widgets/pro_section_header.dart';
import '../providers/events_provider.dart';
import '../widgets/event_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Container(
          height: 46,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.border.withValues(alpha: 0.6), width: 1),
          ),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            onChanged: (v) =>
                ref.read(searchQueryProvider.notifier).state = v,
            style: TextStyle(
                color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Search events, venues...',
              prefixIcon: Icon(Icons.search_rounded,
                  color: AppColors.textMuted, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
      ),
      body: query.isEmpty
          ? _EmptySearchState(
              onPick: (s) {
                _searchCtrl.text = s;
                ref.read(searchQueryProvider.notifier).state = s;
              },
            )
          : resultsAsync.when(
              data: (events) => events.isEmpty
                  ? ProEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No results for "$query"',
                      subtitle: 'Try a different keyword',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: events.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: EventCard(
                          event: events[i],
                          onTap: () =>
                              context.push('/events/${events[i].id}'),
                        ),
                      ),
                    ),
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              error: (e, _) => Center(
                child: Text(e.toString(),
                    style: const TextStyle(color: AppColors.error)),
              ),
            ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  final ValueChanged<String> onPick;

  const _EmptySearchState({required this.onPick});

  @override
  Widget build(BuildContext context) {
    const suggestions = ['Music', 'Conference', 'Sports', 'Comedy', 'Tech'];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProSectionHeader(
            title: 'Popular searches',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: suggestions
                .map((s) => GestureDetector(
                      onTap: () => onPick(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                              color:
                                  AppColors.border.withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.trending_up_rounded,
                                size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              s,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}