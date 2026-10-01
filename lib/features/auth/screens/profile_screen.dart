import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../providers/auth_provider.dart';
import '../../events/providers/bookings_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _notificationsEnabled = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).valueOrNull?.user;
      _nameCtrl.text = user?.name ?? '';
      _phoneCtrl.text = user?.phone ?? '';
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull?.user;
    final bookingsAsync = ref.watch(bookingsProvider);

    // Stats derived from bookings
    final bookings = bookingsAsync.valueOrNull ?? [];
    final confirmedBookings = bookings.where((b) => b.isConfirmed).length;
    final attendedEvents = bookings.where((b) => b.status == 'attended').length;
    final totalSpent = bookings
        .where((b) => !b.isCancelled)
        .fold<double>(0, (sum, b) => sum + b.amount);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ─────────────────────────────────────
          SliverToBoxAdapter(
            child: _ProfileHero(
              name: user?.name ?? 'User',
              email: user?.email ?? '',
              memberSince: user?.createdAt,
              onBack: () => context.pop(),
              onEdit: () => setState(() => _isEditing = !_isEditing),
              isEditing: _isEditing,
            ),
          ),

          // ── Stats Row ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: _StatsRow(
                upcoming: confirmedBookings,
                attended: attendedEvents,
                totalSpent: totalSpent,
              ),
            ),
          ),

          // ── Edit Profile Form (if editing) ──────────────────
          if (_isEditing)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: _EditProfileCard(
                  nameCtrl: _nameCtrl,
                  phoneCtrl: _phoneCtrl,
                  onSave: _saveProfile,
                  onCancel: () => setState(() => _isEditing = false),
                ),
              ),
            ),

          // ── Account Info ────────────────────────────────────
          if (!_isEditing)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _SectionLabel(label: 'Account Info'),
              ),
            ),

          if (!_isEditing)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _InfoCard(
                  items: [
                    _InfoRow(
                      icon: Icons.person_rounded,
                      label: 'Full Name',
                      value: user?.name ?? '—',
                    ),
                    _InfoRow(
                      icon: Icons.email_rounded,
                      label: 'Email',
                      value: user?.email ?? '—',
                    ),
                    _InfoRow(
                      icon: Icons.phone_rounded,
                      label: 'Phone',
                      value: user?.phone ?? 'Not set',
                    ),
                    _InfoRow(
                      icon: Icons.shield_rounded,
                      label: 'Account Role',
                      value: (user?.role ?? 'user').toUpperCase(),
                      valueColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),

          // ── Preferences ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: _SectionLabel(label: 'Preferences'),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: ref.watch(themeProvider) == ThemeMode.dark,
                      onChanged: (_) =>
                          ref.read(themeProvider.notifier).toggleTheme(),
                      activeThumbColor: AppColors.primary,
                      title: Text(
                        'Dark Mode',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        ref.watch(themeProvider) == ThemeMode.dark
                            ? 'Spotify sleek dark aesthetic'
                            : 'Clean crisp light mode',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12),
                      ),
                      secondary: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          ref.watch(themeProvider) == ThemeMode.dark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    Divider(height: 1, color: AppColors.border),
                    SwitchListTile(
                      value: _notificationsEnabled,
                      onChanged: (v) =>
                          setState(() => _notificationsEnabled = v),
                      activeThumbColor: AppColors.primary,
                      title: Text(
                        'Push Notifications',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Event reminders, offers & updates',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12),
                      ),
                      secondary: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Quick Links ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: _SectionLabel(label: 'Quick Links'),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _QuickLinksCard(
                items: [
                  _QuickLink(
                    icon: Icons.confirmation_number_rounded,
                    label: 'My Tickets',
                    iconColor: AppColors.primary,
                    onTap: () => context.push(AppRoutes.myBookings),
                  ),
                  _QuickLink(
                    icon: Icons.room_service_rounded,
                    label: 'Browse Services',
                    iconColor: AppColors.secondary,
                    onTap: () => context.push(AppRoutes.services),
                  ),
                  _QuickLink(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    iconColor: AppColors.tertiary,
                    onTap: () {},
                  ),
                  _QuickLink(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    iconColor: AppColors.textMuted,
                    onTap: () {},
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ),

          // ── Logout Button ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
              child: _LogoutButton(
                onLogout: () => _confirmLogout(context),
              ),
            ),
          ),

          // ── Member Since Footer ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              child: Center(
                child: Text(
                  user?.createdAt != null
                      ? 'Member since ${DateFormat('MMMM yyyy').format(user!.createdAt)}'
                      : '',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: AppBottomNav(currentIndex: 4),
    );
  }

  Future<void> _saveProfile() async {
    // For now just update local state; wire to Firestore when ready
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile updated successfully!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out of EventPro?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Profile Hero ─────────────────────────────────────────────────────────────
class _ProfileHero extends StatelessWidget {
  final String name;
  final String email;
  final DateTime? memberSince;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final bool isEditing;

  const _ProfileHero({
    required this.name,
    required this.email,
    this.memberSince,
    required this.onBack,
    required this.onEdit,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 12, 20, 30),
      decoration: BoxDecoration(
        gradient: AppColors.profileGradient,
      ),
      child: Column(
        children: [
          // Top nav row
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isEditing ? null : AppColors.primaryGradient,
                    color: isEditing ? Colors.white12 : null,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isEditing ? Icons.close_rounded : Icons.edit_rounded,
                        size: 14,
                        color: isEditing ? Colors.white70 : Colors.black,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isEditing ? 'Cancel' : 'Edit',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isEditing ? Colors.white70 : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Avatar with gold ring
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.background,
              ),
              child: CircleAvatar(
                radius: 46,
                backgroundColor: AppColors.secondary,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Name + email
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 12),

          // Member badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.star_rounded, size: 12, color: Colors.black),
                SizedBox(width: 5),
                Text(
                  'EventPro Member',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int upcoming;
  final int attended;
  final double totalSpent;

  const _StatsRow({
    required this.upcoming,
    required this.attended,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 0),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          _StatItem(
            value: '$upcoming',
            label: 'Upcoming',
            icon: Icons.calendar_today_rounded,
            iconColor: AppColors.primary,
          ),
          _VertDivider(),
          _StatItem(
            value: '$attended',
            label: 'Attended',
            icon: Icons.check_circle_rounded,
            iconColor: AppColors.success,
          ),
          _VertDivider(),
          _StatItem(
            value: 'KES ${(totalSpent / 1000).toStringAsFixed(1)}K',
            label: 'Total Spent',
            icon: Icons.payments_rounded,
            iconColor: AppColors.secondary,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 48,
      color: AppColors.border,
    );
  }
}

// ── Edit Profile Card ─────────────────────────────────────────────────────────
class _EditProfileCard extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _EditProfileCard({
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Profile',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: nameCtrl,
            label: 'Full Name',
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: phoneCtrl,
            label: 'Phone Number',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Changes',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ── Info Card ─────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final List<_InfoRow> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          return Column(
            children: [
              items[i],
              if (i < items.length - 1)
                Divider(
                    height: 0, thickness: 0.5, color: AppColors.border,
                    indent: 56),
            ],
          );
        }),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quick Links Card ──────────────────────────────────────────────────────────
class _QuickLinksCard extends StatelessWidget {
  final List<_QuickLink> items;
  const _QuickLinksCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          return Column(
            children: [
              items[i],
              if (i < items.length - 1)
                Divider(
                    height: 0, thickness: 0.5, color: AppColors.border,
                    indent: 56),
            ],
          );
        }),
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;
  final bool showDivider;

  const _QuickLink({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  )),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Logout Button ─────────────────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;
  const _LogoutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onLogout,
        icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
        label: const Text(
          'Sign Out',
          style: TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

