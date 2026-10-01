import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../constants/app_routes.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Multia-style bottom navigation.
///
/// Icon-only destinations on a near-black bar, with the profile
/// rendered as a circular avatar in the final slot. The selected
/// item glows in the brand accent with a small dot indicator.
class AppBottomNav extends ConsumerWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authStateProvider).valueOrNull?.user;

    final barColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFFF3E0);
    final borderColor =
        isDark ? const Color(0xFF1F1F1F) : const Color(0xFFFFCC80);

    return Container(
      decoration: BoxDecoration(
        color: barColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                selected: currentIndex == 0,
                onTap: () => context.go(AppRoutes.home),
              ),
              _NavItem(
                icon: Icons.search_outlined,
                selectedIcon: Icons.search_rounded,
                selected: currentIndex == 1,
                onTap: () => context.push(AppRoutes.search),
              ),
              _NavItem(
                icon: Icons.room_service_outlined,
                selectedIcon: Icons.room_service_rounded,
                selected: currentIndex == 2,
                onTap: () => context.push(AppRoutes.services),
              ),
              _NavItem(
                icon: Icons.confirmation_number_outlined,
                selectedIcon: Icons.confirmation_number_rounded,
                selected: currentIndex == 3,
                onTap: () => context.go(AppRoutes.myBookings),
              ),
              _NavAvatar(
                initial: (user?.name ?? 'U')[0].toUpperCase(),
                selected: currentIndex == 4,
                onTap: () => context.push(AppRoutes.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Icon Destination ───────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? const Color(0xFF6E6E6E) : const Color(0xFF9E6B35);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: selected ? null : onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                selected ? selectedIcon : icon,
                key: ValueKey(selected),
                size: selected ? 25 : 22,
                color: selected ? AppColors.yellow : muted,
                shadows: selected
                    ? [
                        Shadow(
                          color: AppColors.yellow.withValues(alpha: 0.55),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 5),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 4 : 0,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.yellow,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Avatar Destination ─────────────────────────────────────────
class _NavAvatar extends StatelessWidget {
  final String initial;
  final bool selected;
  final VoidCallback onTap;

  const _NavAvatar({
    required this.initial,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: selected ? null : onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: selected ? AppColors.primaryGradient : null,
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE8D9C0)),
                width: 1.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.45),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Text(
                initial,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
