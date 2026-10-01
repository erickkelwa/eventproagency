import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../providers/admin_provider.dart';

class AdminEventListScreen extends ConsumerWidget {
  const AdminEventListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(adminEventsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('My Events',
            style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () => ref.read(adminEventsProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminEventCreate),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Event',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: eventsAsync.when(
        data: (events) => events.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🎪', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 16),
                    Text('No events yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        )),
                    const SizedBox(height: 8),
                    Text('Create your first event!',
                        style: TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.push(AppRoutes.adminEventCreate),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create Event'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                itemCount: events.length,
                itemBuilder: (_, i) {
                  final event = events[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      leading: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.event_rounded,
                            color: Colors.white, size: 24),
                      ),
                      title: Text(
                        event.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEE, MMM d · h:mm a')
                                .format(event.date),
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${event.bookedCount ?? 0}/${event.capacity} booked · ${event.formattedPrice}',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded,
                            color: AppColors.textMuted),
                        color: AppColors.card,
                        onSelected: (action) async {
                          if (action == 'edit') {
                            context.push(
                                '/admin/events/${event.id}/edit');
                          } else if (action == 'delete') {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: AppColors.card,
                                title: Text('Delete Event?',
                                    style: TextStyle(
                                        color: AppColors.textPrimary)),
                                content: Text(
                                    'Are you sure you want to delete "${event.title}"?',
                                    style: TextStyle(
                                        color: AppColors.textSecondary)),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete',
                                        style: TextStyle(
                                            color: AppColors.error)),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true && context.mounted) {
                              await ref
                                  .read(adminEventsProvider.notifier)
                                  .deleteEvent(int.parse(event.id));
                            }
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              Icon(Icons.edit_rounded,
                                  color: AppColors.primary, size: 18),
                              SizedBox(width: 10),
                              Text('Edit',
                                  style: TextStyle(
                                      color: AppColors.textPrimary)),
                            ]),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete_rounded,
                                  color: AppColors.error, size: 18),
                              SizedBox(width: 10),
                              Text('Delete',
                                  style: TextStyle(color: AppColors.error)),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
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