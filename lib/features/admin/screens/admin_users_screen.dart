import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/models/user_model.dart';

/// Source of truth: Firestore `users` — every app sign-up (email/password or
/// Google) creates a doc there, so new registrations appear in real time.
/// Laravel `/admin/users` is then used best-effort (needs Sanctum token) to
/// enrich rows with booking counts and payment issues.
final adminUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .snapshots()
      .asyncMap((snap) async {
    final users = snap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      return UserModel.fromJson(data);
    }).toList();

    try {
      final response =
          await DioClient.instance.dio.get(ApiConstants.adminUsers);
      final laravelUsers = response.data['users'] as List? ?? [];
      final byEmail = {
        for (final u in laravelUsers.whereType<Map>())
          '${u['email']}'.toLowerCase(): u
      };
      for (var i = 0; i < users.length; i++) {
        final l = byEmail[users[i].email.toLowerCase()];
        if (l == null) continue;
        final issuesList = l['issues'];
        users[i] = users[i].copyWith(
          bookingCount: (l['bookings_count'] as num?)?.toInt() ?? 0,
          hasIssues: l['has_issues'] == true,
          issuesCount: issuesList is List ? issuesList.length : 0,
          issues: issuesList is List
              ? issuesList.whereType<Map>().map(Map<String, dynamic>.from).toList()
              : null,
        );
      }
    } catch (_) {
      // No Sanctum token / API offline — Firestore data alone is still real.
    }

    users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return users;
  });
});

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _searchQuery = '';
  String _selectedRole = 'all';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'User Management',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search by name or email...',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Filter dropdown
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      dropdownColor: AppColors.card,
                      icon: Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 18),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Roles', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'admin', child: Text('Admins', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'user', child: Text('Customers', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(
                          value: 'issues',
                          child: Row(
                            children: [
                              Text('⚠️ Has Issues', style: TextStyle(fontSize: 13, color: AppColors.error, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedRole = v);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // User list
          Expanded(
            child: usersAsync.when(
              data: (users) {
                final filtered = users.where((u) {
                  final matchesQuery = u.name.toLowerCase().contains(_searchQuery) ||
                      u.email.toLowerCase().contains(_searchQuery) ||
                      (u.phone?.contains(_searchQuery) ?? false);
                  if (_selectedRole == 'issues') {
                    return matchesQuery && u.hasIssues;
                  }
                  final matchesRole = _selectedRole == 'all' || u.role.toLowerCase() == _selectedRole;
                  return matchesQuery && matchesRole;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search_rounded, size: 54, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No users found',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final u = filtered[i];
                    final isAdmin = u.role.toLowerCase() == 'admin';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isAdmin
                              ? AppColors.primary.withValues(alpha: 0.35)
                              : AppColors.border,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                          // User Avatar
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: isAdmin
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : AppColors.secondary.withValues(alpha: 0.1),
                            child: Text(
                              u.name.isNotEmpty ? u.name[0].toUpperCase() : 'U',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isAdmin ? AppColors.primary : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        u.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isAdmin
                                            ? AppColors.primary.withValues(alpha: 0.15)
                                            : AppColors.surface,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isAdmin ? AppColors.primary : AppColors.border,
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        isAdmin ? 'ADMIN' : 'USER',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: isAdmin ? AppColors.primary : AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  u.email,
                                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                ),
                                if (u.phone != null && u.phone!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    u.phone!,
                                    style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Joined date & Bookings
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  '${u.bookingCount} Orders',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                DateFormat('MMM d, y').format(u.createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (u.hasIssues) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Issue: ${u.issuesCount} failed payment/order attempt detected',
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (u.phone != null && u.phone!.isNotEmpty) ...[
                                InkWell(
                                  onTap: () {
                                    final clean = u.phone!.replaceAll(RegExp(r'\D'), '');
                                    final phone = clean.startsWith('0') ? '254${clean.substring(1)}' : clean;
                                    launchUrl(Uri.parse('https://wa.me/$phone'), mode: LaunchMode.externalApplication);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF25D366),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('WhatsApp', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => launchUrl(Uri.parse('tel:${u.phone}')),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Call', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(
                child: Text('Failed to load users: $err', style: const TextStyle(color: AppColors.error)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
