import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/network_exception.dart';
import '../../../core/constants/api_constants.dart';
import '../../events/models/event_model.dart';

// ── Dashboard Stats Model ──────────────────────────────────
class DashboardStats {
  final double totalRevenue;
  final int totalBookings;
  final int totalEvents;
  final int totalUsers;
  final List<Map<String, dynamic>> revenueChart;
  final List<Map<String, dynamic>> bookingsChart;

  const DashboardStats({
    required this.totalRevenue,
    required this.totalBookings,
    required this.totalEvents,
    required this.totalUsers,
    required this.revenueChart,
    required this.bookingsChart,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        totalRevenue: (json['total_revenue'] as num).toDouble(),
        totalBookings: json['total_bookings'] as int,
        totalEvents: json['total_events'] as int,
        totalUsers: json['total_users'] as int,
        revenueChart: List<Map<String, dynamic>>.from(
            json['revenue_chart'] as List? ?? []),
        bookingsChart: List<Map<String, dynamic>>.from(
            json['bookings_chart'] as List? ?? []),
      );
}

// ── Dashboard Provider ─────────────────────────────────────
final dashboardStatsProvider =
    FutureProvider<DashboardStats>((ref) async {
  try {
    final response =
        await DioClient.instance.dio.get(ApiConstants.adminDashboard);
    return DashboardStats.fromJson(response.data);
  } on DioException catch (e) {
    throw NetworkException.fromDioError(e);
  }
});

// ── Admin Events Provider ──────────────────────────────────
final adminEventsProvider =
    AsyncNotifierProvider<AdminEventsNotifier, List<EventModel>>(
  AdminEventsNotifier.new,
);

class AdminEventsNotifier extends AsyncNotifier<List<EventModel>> {
  @override
  Future<List<EventModel>> build() async {
    return _fetch();
  }

  Future<List<EventModel>> _fetch() async {
    final response =
        await DioClient.instance.dio.get(ApiConstants.adminEvents);
    return (response.data['data'] as List)
        .map((e) => EventModel.fromJson(e))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> deleteEvent(int id) async {
    try {
      await DioClient.instance.dio.delete('${ApiConstants.adminEvents}/$id');
      state = AsyncData(
        state.valueOrNull?.where((e) => e.id.toString() != id.toString()).toList() ?? [],
      );
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }
}
