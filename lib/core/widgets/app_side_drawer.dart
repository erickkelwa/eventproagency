import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import '../constants/app_routes.dart';
import '../localization/language_provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/events/widgets/notifications_modal.dart';

/// Premium Pro Side Drawer navigation offering high-utility quick links:
/// • User Profile header with role badge
/// • Dark/Light mode live toggle switch
/// • Saved / Bookmarked Events
/// • Nearby Events Google Map
/// • Book Event Vendors / Services
/// • Admin Control Center (for admins)
/// • WhatsApp Support & Hotline
/// • Language & App Settings
class AppSideDrawer extends ConsumerWidget {
  const AppSideDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull?.user;
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Drawer(
      backgroundColor: AppColors.background,
      elevation: 16,
      child: SafeArea(
        child: Column(
          children: [
            // ── User Header ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user?.name ?? 'Guest User',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (user?.isAdmin == true) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user?.email ?? 'Sign in to access all features',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Menu Options ─────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                children: [
                  _DrawerSectionLabel('EXPERIENCE & DISCOVERY'),
                  _DrawerTile(
                    icon: Icons.explore_rounded,
                    title: 'Discover Events',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.home);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.map_rounded,
                    title: 'Nearby Events Map',
                    subtitle: 'Explore venues in Nairobi & Kenya',
                    color: const Color(0xFF3B82F6),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/events/map');
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.confirmation_number_rounded,
                    title: 'My Digital Tickets',
                    subtitle: 'Gate passes & QR vouchers',
                    color: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.myBookings);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.room_service_rounded,
                    title: 'Event Vendors & Services',
                    subtitle: 'Catering, Sound, Decor, DJ',
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.services);
                    },
                  ),

                  const SizedBox(height: 14),
                  _DrawerSectionLabel('COMMUNICATION'),
                  _DrawerTile(
                    icon: Icons.notifications_rounded,
                    title: 'Notifications Center',
                    subtitle: 'Alerts, ticket updates, reminders',
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.pop(context);
                      NotificationsModal.show(context);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.chat_bubble_rounded,
                    title: 'WhatsApp Concierge',
                    subtitle: '24/7 dedicated support',
                    color: const Color(0xFF25D366),
                    onTap: () async {
                      final uri = Uri.parse('https://wa.me/254728664792?text=Hello%20EventPro%20Support');
                      if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                  ),


                  if (user?.isAdmin == true) ...[
                    const SizedBox(height: 16),
                    // Admin Control Center Banner
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        context.push(AppRoutes.adminLogin);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryDark,
                              const Color(0xFF7C3AED),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.45),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Admin Control Center',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Revenue - Events - Analytics',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                    _DrawerTile(
                      icon: Icons.people_alt_rounded,
                      title: 'User Management',
                      subtitle: 'View and manage attendees',
                      color: const Color(0xFF06B6D4),
                      onTap: () {
                        Navigator.pop(context);
                        context.push(AppRoutes.adminUsers);
                      },
                    ),
                    _DrawerTile(
                      icon: Icons.event_note_rounded,
                      title: 'Manage Events',
                      subtitle: 'Create, edit and publish events',
                      color: const Color(0xFFF59E0B),
                      onTap: () {
                        Navigator.pop(context);
                        context.push(AppRoutes.adminEvents);
                      },
                    ),
                  ],

                  const SizedBox(height: 14),
                  _DrawerSectionLabel('PREFERENCES'),
                  // Dark Mode Switch Tile
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.amber : Colors.indigo).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: isDark ? Colors.amber : Colors.indigo,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Theme Mode',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        isDark ? 'Dark Theme' : 'Play Store White',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      trailing: Switch.adaptive(
                        value: isDark,
                        activeTrackColor: AppColors.primary,
                        onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
                      ),
                    ),
                  ),

                  // Language Switcher Tile
                  Consumer(
                    builder: (context, ref, _) {
                      final currentLang = ref.watch(languageProvider);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.language_rounded,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'Language / Lugha',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            '${currentLang.flag} ${currentLang.title}',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          trailing: PopupMenuButton<AppLanguage>(
                            initialValue: currentLang,
                            icon: const Icon(Icons.arrow_drop_down_circle_outlined, size: 20),
                            onSelected: (AppLanguage lang) {
                              ref.read(languageProvider.notifier).state = lang;
                            },
                            itemBuilder: (BuildContext context) => AppLanguage.values
                                .map((lang) => PopupMenuItem<AppLanguage>(
                                      value: lang,
                                      child: Row(
                                        children: [
                                          Text(lang.flag, style: const TextStyle(fontSize: 18)),
                                          const SizedBox(width: 10),
                                          Text(
                                            lang.title,
                                            style: TextStyle(
                                              fontWeight: lang == currentLang
                                                  ? FontWeight.w800
                                                  : FontWeight.w500,
                                              color: lang == currentLang
                                                  ? AppColors.primary
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      );
                    },
                  ),

                  _DrawerTile(
                    icon: Icons.person_rounded,
                    title: 'Account Settings',
                    subtitle: 'Manage profile & security',
                    color: AppColors.textMuted,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.profile);
                    },
                  ),
                ],
              ),
            ),

            // ── Footer ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Text(
                    'EventPro v1.0.0 Pro',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await ref.read(authStateProvider.notifier).logout();
                      if (context.mounted) context.go(AppRoutes.login);
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.logout_rounded, size: 16, color: AppColors.error),
                        const SizedBox(width: 4),
                        const Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                      ],
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

class _DrawerSectionLabel extends StatelessWidget {
  final String label;
  const _DrawerSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: AppColors.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              )
            : null,
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
        onTap: onTap,
      ),
    );
  }
}
