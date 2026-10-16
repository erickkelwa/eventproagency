import 'dart:ui';
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
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Bar ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 90,
                floating: true,
                pinned: true,
                backgroundColor: AppColors.background.withValues(alpha: 0.8),
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 14.0),
                  child: Center(
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 18),
                      ),
                      tooltip: 'Back to User App',
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.home);
                        }
                      },
                    ),
                  ),
                ),
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                title: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Welcome back, ${user?.name.split(' ').first ?? 'Admin'}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.border.withValues(alpha: 0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.qr_code_scanner_rounded, color: AppColors.textPrimary, size: 22),
                        onPressed: () => context.push(AppRoutes.adminQrScanner),
                        tooltip: 'Scan QR',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: GestureDetector(
                      onTap: () async {
                        await ref.read(authStateProvider.notifier).logout();
                        if (context.mounted) context.go(AppRoutes.login);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.card,
                          child: const Icon(Icons.power_settings_new_rounded,
                              color: AppColors.error, size: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),

              // ── Content ────────────────────────────────────
              SliverToBoxAdapter(
                child: statsAsync.when(
                  data: (stats) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // KPI Grid
                        GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.25,
                          children: [
                            _KpiCard(
                              label: 'Total Revenue',
                              value: 'KES ${NumberFormat.compact().format(stats.totalRevenue)}',
                              icon: Icons.account_balance_wallet_rounded,
                              gradient: AppColors.primaryGradient,
                              delay: 0,
                            ),
                            _KpiCard(
                              label: 'Bookings',
                              value: stats.totalBookings.toString(),
                              icon: Icons.confirmation_number_rounded,
                              gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)]),
                              delay: 100,
                            ),
                            _KpiCard(
                              label: 'Active Events',
                              value: stats.totalEvents.toString(),
                              icon: Icons.event_available_rounded,
                              gradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFF97316)]),
                              delay: 200,
                            ),
                            GestureDetector(
                              onTap: () => context.push(AppRoutes.adminUsers),
                              child: _KpiCard(
                                label: 'Total Users',
                                value: stats.totalUsers.toString(),
                                icon: Icons.groups_rounded,
                                gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                                delay: 300,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Quick Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => context.push(AppRoutes.adminUsers),
                              icon: const Icon(Icons.people_alt_rounded, size: 16),
                              label: const Text('All Users'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _QuickActionTile(
                                icon: Icons.add_circle_outline_rounded,
                                label: 'New Event',
                                color: AppColors.primary,
                                onTap: () => context.push(AppRoutes.adminEventCreate),
                              ),
                              const SizedBox(width: 12),
                              _QuickActionTile(
                                icon: Icons.event_note_rounded,
                                label: 'Manage',
                                color: const Color(0xFF3B82F6),
                                onTap: () => context.push(AppRoutes.adminEvents),
                              ),
                              const SizedBox(width: 12),
                              _QuickActionTile(
                                icon: Icons.people_alt_rounded,
                                label: 'Users',
                                color: const Color(0xFF10B981),
                                onTap: () => context.push(AppRoutes.adminUsers),
                              ),
                              const SizedBox(width: 12),
                              _QuickActionTile(
                                icon: Icons.qr_code_scanner_rounded,
                                label: 'Scan QR',
                                color: const Color(0xFF8B5CF6),
                                onTap: () => context.push(AppRoutes.adminQrScanner),
                              ),
                              const SizedBox(width: 12),
                              _QuickActionTile(
                                icon: Icons.insights_rounded,
                                label: 'Reports',
                                color: const Color(0xFFF59E0B),
                                onTap: () => context.push(AppRoutes.adminReports),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Revenue Chart ─────────────────────
                        _ChartCard(
                          title: 'Revenue Analytics (7 Days)',
                          child: stats.revenueChart.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.analytics_outlined, size: 48, color: AppColors.border),
                                      const SizedBox(height: 12),
                                      Text('Not enough data', style: TextStyle(color: AppColors.textMuted)),
                                    ],
                                  ),
                                )
                              : BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: _getMaxY(stats.revenueChart),
                                    barTouchData: BarTouchData(
                                      enabled: true,
                                      touchTooltipData: BarTouchTooltipData(
                                        getTooltipColor: (_) => AppColors.cardHover,
                                        tooltipRoundedRadius: 8,
                                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                          final item = stats.revenueChart[groupIndex];
                                          final label = (item['label'] ?? item['day'] ?? '').toString();
                                          return BarTooltipItem(
                                            '$label\n',
                                            TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                                            children: [
                                              TextSpan(
                                                text: 'KES ${NumberFormat.compact().format(rod.toY)}',
                                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final idx = value.toInt();
                                            if (idx < 0 || idx >= stats.revenueChart.length) return const SizedBox.shrink();
                                            final item = stats.revenueChart[idx];
                                            final label = (item['label'] ?? item['day'] ?? '').toString();
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Text(
                                                label,
                                                style: TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 42,
                                          getTitlesWidget: (value, meta) {
                                            if (value == 0) return const SizedBox.shrink();
                                            return Text(
                                              NumberFormat.compact().format(value),
                                              style: TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    ),
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: _getMaxY(stats.revenueChart) / 4 > 0 ? _getMaxY(stats.revenueChart) / 4 : 1,
                                      getDrawingHorizontalLine: (value) => FlLine(
                                        color: AppColors.border.withValues(alpha: 0.5),
                                        strokeWidth: 1,
                                        dashArray: [5, 5],
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    barGroups: stats.revenueChart.asMap().entries.map((e) {
                                      final rawVal = e.value['amount'] ?? e.value['value'] ?? 0;
                                      final val = (rawVal is num) ? rawVal.toDouble() : (double.tryParse(rawVal.toString()) ?? 0.0);
                                      return BarChartGroupData(
                                        x: e.key,
                                        barRods: [
                                          BarChartRodData(
                                            toY: val,
                                            gradient: AppColors.primaryGradient,
                                            width: 22,
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                            backDrawRodData: BackgroundBarChartRodData(
                                              show: true,
                                              toY: _getMaxY(stats.revenueChart),
                                              color: AppColors.backgroundSecondary,
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 24),

                        // ── Bookings Volume Trend Chart ────────
                        _ChartCard(
                          title: 'Ticket Bookings Volume (7 Days)',
                          child: stats.bookingsChart.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.confirmation_number_outlined, size: 48, color: AppColors.border),
                                      const SizedBox(height: 12),
                                      Text('No booking volume data', style: TextStyle(color: AppColors.textMuted)),
                                    ],
                                  ),
                                )
                              : BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: _getMaxY(stats.bookingsChart, valueKey: 'count'),
                                    barTouchData: BarTouchData(
                                      enabled: true,
                                      touchTooltipData: BarTouchTooltipData(
                                        getTooltipColor: (_) => AppColors.cardHover,
                                        tooltipRoundedRadius: 8,
                                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                          final item = stats.bookingsChart[groupIndex];
                                          final label = (item['label'] ?? item['day'] ?? '').toString();
                                          return BarTooltipItem(
                                            '$label\n',
                                            TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                                            children: [
                                              TextSpan(
                                                text: '${rod.toY.toInt()} Bookings',
                                                style: const TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final idx = value.toInt();
                                            if (idx < 0 || idx >= stats.bookingsChart.length) return const SizedBox.shrink();
                                            final item = stats.bookingsChart[idx];
                                            final label = (item['label'] ?? item['day'] ?? '').toString();
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Text(
                                                label,
                                                style: TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 34,
                                          getTitlesWidget: (value, meta) {
                                            if (value == 0) return const SizedBox.shrink();
                                            return Text(
                                              value.toInt().toString(),
                                              style: TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    ),
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: _getMaxY(stats.bookingsChart, valueKey: 'count') / 4 > 0
                                          ? _getMaxY(stats.bookingsChart, valueKey: 'count') / 4
                                          : 1,
                                      getDrawingHorizontalLine: (value) => FlLine(
                                        color: AppColors.border.withValues(alpha: 0.5),
                                        strokeWidth: 1,
                                        dashArray: [5, 5],
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    barGroups: stats.bookingsChart.asMap().entries.map((e) {
                                      final rawVal = e.value['count'] ?? e.value['amount'] ?? 0;
                                      final val = (rawVal is num) ? rawVal.toDouble() : (double.tryParse(rawVal.toString()) ?? 0.0);
                                      return BarChartGroupData(
                                        x: e.key,
                                        barRods: [
                                          BarChartRodData(
                                            toY: val,
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                            width: 22,
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                            backDrawRodData: BackgroundBarChartRodData(
                                              show: true,
                                              toY: _getMaxY(stats.bookingsChart, valueKey: 'count'),
                                              color: AppColors.backgroundSecondary,
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                        ),
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
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                          const SizedBox(height: 16),
                          Text(e.toString(), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => ref.refresh(dashboardStatsProvider),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () => context.push(AppRoutes.adminLogin),
                                icon: const Icon(Icons.login_rounded),
                                label: const Text('Admin Login'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _getMaxY(List<dynamic> chartData, {String valueKey = 'amount'}) {
    if (chartData.isEmpty) return 100;
    double max = 0;
    for (var d in chartData) {
      final raw = d[valueKey] ?? d['amount'] ?? d['count'] ?? d['value'] ?? 0;
      final val = (raw is num) ? raw.toDouble() : (double.tryParse(raw.toString()) ?? 0.0);
      if (val > max) {
        max = val;
      }
    }
    return max == 0 ? 100 : max * 1.25;
  }
}

// ── KPI Card Widget (Animated) ────────────────────────────────────────
class _KpiCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final LinearGradient gradient;
  final int delay;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.delay,
  });

  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.border.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: widget.gradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 20),
                  ),
                  Icon(Icons.trending_up_rounded, color: AppColors.success, size: 20),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              Icon(Icons.more_horiz_rounded, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(height: 220, child: child),
        ],
      ),
    );
  }
}

// ── Quick Action Tile ──────────────────────────────────────
class _QuickActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        transform: Matrix4.diagonal3Values(
          _isPressed ? 0.92 : 1.0,
          _isPressed ? 0.92 : 1.0,
          1.0,
        ),
        child: Container(
          width: 90,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _isPressed ? 0.1 : 0.15),
                blurRadius: _isPressed ? 5 : 12,
                offset: Offset(0, _isPressed ? 2 : 6),
              ),
            ],
            border: Border.all(color: widget.color.withValues(alpha: 0.2), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}