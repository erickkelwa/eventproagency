import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Reports Provider ───────────────────────────────────────
final reportsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response =
      await DioClient.instance.dio.get(ApiConstants.adminReports);
  return response.data as Map<String, dynamic>;
});

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Reports & Analytics',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () => ref.invalidate(reportsProvider),
          ),
        ],
      ),
      body: reportsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(err.toString(),
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.invalidate(reportsProvider),
                child: const Text('Retry',
                    style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        ),
        data: (data) => _ReportsBody(data: data),
      ),
    );
  }
}

class _ReportsBody extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ReportsBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final revenueChart =
        List<Map<String, dynamic>>.from(data['revenue_chart'] as List? ?? []);
    final topEvents =
        List<Map<String, dynamic>>.from(data['top_events'] as List? ?? []);
    final categoryBreakdown = Map<String, dynamic>.from(
        data['category_breakdown'] as Map? ?? {});

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Download Buttons ──────────────────────────────
        Row(
          children: [
            Expanded(
              child: _DownloadButton(
                icon: Icons.picture_as_pdf_rounded,
                label: 'Download PDF',
                color: AppColors.error,
                onTap: () => _downloadReport(context, 'pdf'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DownloadButton(
                icon: Icons.table_chart_rounded,
                label: 'Download Excel',
                color: AppColors.success,
                onTap: () => _downloadReport(context, 'excel'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Revenue Chart ─────────────────────────────────
        _SectionHeader('Revenue (Last 30 Days)'),
        const SizedBox(height: 12),
        _RevenueChart(data: revenueChart),
        const SizedBox(height: 24),

        // ── Category Breakdown ────────────────────────────
        _SectionHeader('Bookings by Category'),
        const SizedBox(height: 12),
        _CategoryBreakdown(data: categoryBreakdown),
        const SizedBox(height: 24),

        // ── Top Events ────────────────────────────────────
        _SectionHeader('Top Events'),
        const SizedBox(height: 12),
        ...topEvents.asMap().entries.map(
              (entry) => _TopEventTile(
                rank: entry.key + 1,
                event: entry.value,
              ),
            ),
        const SizedBox(height: 40),
      ],
    );
  }

  void _downloadReport(BuildContext context, String type) async {
    final uri = Uri.parse(
      '${ApiConstants.adminReports}?format=$type',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open report'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ── Revenue Chart ──────────────────────────────────────────
class _RevenueChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _RevenueChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text('No data yet',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    final spots = data.asMap().entries.map((e) {
      return FlSpot(
        e.key.toDouble(),
        (e.value['amount'] as num).toDouble(),
      );
    }).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.border,
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (val, _) => Text(
                  'K${(val / 1000).toStringAsFixed(0)}',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    AppColors.secondary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category Breakdown ─────────────────────────────────────
class _CategoryBreakdown extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CategoryBreakdown({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text('No data yet',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    final entries = data.entries.toList();
    final total = entries.fold<double>(
        0, (sum, e) => sum + (e.value as num).toDouble());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: entries.map((e) {
          final pct = total > 0 ? (e.value as num) / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    Text('${(pct * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct.toDouble(),
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Top Event Tile ─────────────────────────────────────────
class _TopEventTile extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> event;
  const _TopEventTile({required this.rank, required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: rank == 1
                  ? const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)])
                  : rank == 2
                      ? const LinearGradient(
                          colors: [Color(0xFFC0C0C0), Color(0xFFA0A0A0)])
                      : const LinearGradient(
                          colors: [Color(0xFFCD7F32), Color(0xFFB8622E)]),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'] as String? ?? '',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${event['bookings']} bookings',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            'KES ${NumberFormat.compact().format(event['revenue'] ?? 0)}',
            style: const TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ── Download Button ────────────────────────────────────────
class _DownloadButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DownloadButton({
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}