import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final user = ref.watch(authStateProvider).valueOrNull?.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.background,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Welcome, ${user?.name.split(' ').first ?? 'Admin'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.qr_code_scanner_rounded,
                    color: AppColors.textPrimary),
                onPressed: () => context.push(AppRoutes.adminQrScanner),
                tooltip: 'Scan QR',
              ),
              IconButton(
                icon: Icon(Icons.bar_chart_rounded,
                    color: AppColors.textPrimary),
                onPressed: () => context.push(AppRoutes.adminReports),
                tooltip: 'Reports',
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () async {
                    await ref.read(authStateProvider.notifier).logout();
                    if (context.mounted) context.go(AppRoutes.login);
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.error.withValues(alpha: 0.2),
                    child: const Icon(Icons.logout_rounded,
                        color: AppColors.error, size: 18),
                  ),
                ),
              ),
            ],
          ),

          // ── KPI Cards ────────────────────────────────────
          SliverToBoxAdapter(
            child: statsAsync.when(
              data: (stats) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  children: [
                    // Top row
                    Row(
                      children: [
                        Expanded(
                          child: _KpiCard(
                            label: 'Total Revenue',
                            value:
                                'KES ${NumberFormat.compact().format(stats.totalRevenue)}',
                            icon: Icons.payments_rounded,
                            gradient: AppColors.primaryGradient,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KpiCard(
                            label: 'Bookings',
                            value: stats.totalBookings.toString(),
                            icon: Icons.confirmation_number_rounded,
                            gradient: const LinearGradient(colors: [
                              Color(0xFF06B6D4),
                              Color(0xFF0EA5E9)
                            ]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _KpiCard(
                            label: 'Events',
                            value: stats.totalEvents.toString(),
                            icon: Icons.event_rounded,
                            gradient: const LinearGradient(colors: [
                              Color(0xFFEC4899),
                              Color(0xFFF97316)
                            ]),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KpiCard(
                            label: 'Users',
                            value: stats.totalUsers.toString(),
                            icon: Icons.people_rounded,
                            gradient: const LinearGradient(colors: [
                              Color(0xFF10B981),
                              Color(0xFF059669)
                            ]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Revenue Chart ─────────────────────
                    _ChartCard(
                      title: 'Revenue (Last 7 Days)',
                      child: stats.revenueChart.isEmpty
                          ? Center(
                              child: Text('No data yet',
                                  style: TextStyle(
                                      color: AppColors.textMuted)))
                          : BarChart(
                              BarChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (_) => FlLine(
                                    color: AppColors.border,
                                    strokeWidth: 0.5,
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (v, _) {
                                        final idx = v.toInt();
                                        if (idx >= stats.revenueChart.length) {
                                          return const SizedBox.shrink();
                                        }
                                        return Text(
                                          stats.revenueChart[idx]['label'] ??
                                              '',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                barGroups: stats.revenueChart
                                    .asMap()
                                    .entries
                                    .map(
                                      (e) => BarChartGroupData(
                                        x: e.key,
                                        barRods: [
                                          BarChartRodData(
                                            toY: (e.value['value'] as num)
                                                .toDouble(),
                                            gradient:
                                                AppColors.primaryGradient,
                                            width: 16,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                        ],
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // ── Quick Actions ─────────────────────
                    Row(
                      children: [
                        Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.add_circle_rounded,
                            label: 'New Event',
                            color: AppColors.primary,
                            onTap: () => context.push(AppRoutes.adminEventCreate),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.event_rounded,
                            label: 'My Events',
                            color: AppColors.secondary,
                            onTap: () => context.push(AppRoutes.adminEvents),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.qr_code_scanner_rounded,
                            label: 'Scan QR',
                            color: AppColors.tertiary,
                            onTap: () =>
                                context.push(AppRoutes.adminQrScanner),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.download_rounded,
                            label: 'Reports',
                            color: AppColors.warning,
                            onTap: () => context.push(AppRoutes.adminReports),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(e.toString(),
                        style:
                            const TextStyle(color: AppColors.error)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          ref.refresh(dashboardStatsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── KPI Card Widget ────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final LinearGradient gradient;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chart Container ────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(height: 160, child: child),
        ],
      ),
    );
  }
}

// ── Quick Action Tile ──────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}