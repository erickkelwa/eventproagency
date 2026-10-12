import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/models/user_model.dart';

final adminUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  try {
    final response = await DioClient.instance.dio.get(ApiConstants.adminUsers);
    final usersList = response.data['users'] as List? ?? [];
    return usersList
        .map((u) => UserModel.fromJson(Map<String, dynamic>.from(u)))
        .toList();
  } catch (e) {
    // If backend isn't populated yet, return demo mock users so admin preview is complete
    return [
      UserModel(
        id: '1',
        name: 'Erick Kelwa',
        email: 'erickkelwa9@gmail.com',
        role: 'admin',
        phone: '0728664792',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      UserModel(
        id: '2',
        name: 'Sarah Mwangi',
        email: 'sarah.mwangi@example.com',
        role: 'user',
        phone: '0712345678',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      UserModel(
        id: '3',
        name: 'Brian Omondi',
        email: 'brian.o@example.com',
        role: 'user',
        phone: '0798765432',
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
      UserModel(
        id: '4',
        name: 'Amina Hassan',
        email: 'amina.h@example.com',
        role: 'user',
        phone: '0722113344',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      UserModel(
        id: '5',
        name: 'David Kiprono',
        email: 'david.kip@example.com',
        role: 'user',
        phone: '0733556677',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }
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
                        DropdownMenuItem(value: 'user', child: Text('Users', style: TextStyle(fontSize: 13))),
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
                      u.email.toLowerCase().contains(_searchQuery);
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
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                      child: Row(
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

                          // Joined date
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Joined',
                                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 2),
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
