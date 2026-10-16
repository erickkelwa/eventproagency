import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final IconData icon;
  final Color color;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.color,
    this.isRead = false,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      time: time,
      icon: icon,
      color: color,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'time': time.toIso8601String(),
    'isRead': isRead,
  };

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
      icon: Icons.notifications_rounded,
      color: AppColors.primary,
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<NotificationItem>>((ref) {
  return NotificationsNotifier();
});

class NotificationsNotifier extends StateNotifier<List<NotificationItem>> {
  static const _storageKey = 'eventpro_persisted_notifications_v2';
  static const _clearedFlagKey = 'eventpro_notifications_has_been_cleared_v2';

  NotificationsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasBeenCleared = prefs.getBool(_clearedFlagKey) ?? false;
      
      // If the user previously clicked "Clear all", respect it! Keep it completely empty.
      if (hasBeenCleared) {
        state = [];
        return;
      }

      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        state = decoded.map((e) => NotificationItem.fromJson(e as Map<String, dynamic>)).toList();
        return;
      }

      // Default initial welcome notifications for first-time launch
      final initial = [
        NotificationItem(
          id: '1',
          title: 'Welcome to EventPro Kenya 🎉',
          message: 'Explore concerts, VIP passes & event equipment (sound, catering, chairs).',
          time: DateTime.now().subtract(const Duration(minutes: 10)),
          icon: Icons.celebration_rounded,
          color: AppColors.primary,
          isRead: false,
        ),
        NotificationItem(
          id: '2',
          title: 'M-Pesa STK Push Ready 💳',
          message: 'Instant ticket passes via Safaricom M-Pesa with instant digital QR access.',
          time: DateTime.now().subtract(const Duration(hours: 1)),
          icon: Icons.phone_android_rounded,
          color: AppColors.success,
          isRead: false,
        ),
        NotificationItem(
          id: '3',
          title: 'Event Equipment Rentals 🎪',
          message: 'Need sound systems, tents, or food catering? Book with verified vendors.',
          time: DateTime.now().subtract(const Duration(hours: 5)),
          icon: Icons.speaker_rounded,
          color: AppColors.secondary,
          isRead: true,
        ),
      ];

      state = initial;
      await _save();
    } catch (_) {
      // Fallback
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }

  Future<void> clearAll() async {
    state = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_clearedFlagKey, true);
      await prefs.remove(_storageKey);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
    await _save();
  }

  Future<void> markAsRead(String id) async {
    state = state.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
    await _save();
  }

  Future<void> remove(String id) async {
    state = state.where((n) => n.id != id).toList();
    await _save();
  }
}
