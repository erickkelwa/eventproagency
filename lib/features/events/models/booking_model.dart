import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class BookingModel extends Equatable {
  final String id;
  final String userId;
  final String eventId;
  final String eventTitle;
  final DateTime eventDate;
  final String venue;
  final String category;
  final double amount;
  final String status; // 'confirmed' | 'pending' | 'attended' | 'cancelled'
  final String ticketCode;
  final String? imageUrl;
  final DateTime createdAt;
  final int quantity;

  /// Payment reference (EP…) that issued this ticket. Lets the app open the
  /// server-generated receipt/soft copy and guarantees one ticket per payment.
  final String? transactionId;

  const BookingModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
    required this.venue,
    required this.category,
    required this.amount,
    required this.status,
    required this.ticketCode,
    this.imageUrl,
    required this.createdAt,
    this.quantity = 1,
    this.transactionId,
  });

  bool get isUpcoming => eventDate.isAfter(DateTime.now()) && status != 'cancelled';
  bool get isPast => eventDate.isBefore(DateTime.now()) || status == 'attended';
  bool get isCancelled => status == 'cancelled';
  bool get isConfirmed => status == 'confirmed';

  // ── Tolerant parsing ───────────────────────────────────────
  // Firestore/SQLite values arrive as int, double or numeric string depending
  // on who wrote them, and dates as ISO string or Timestamp. Anything stricter
  // throws a cast error and blanks the whole "My Tickets" list.
  static double _toDouble(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

  static int _toInt(dynamic v, [int fallback = 1]) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? fallback);

  static String _toStr(dynamic v, [String fallback = '']) =>
      v is String ? v : (v?.toString() ?? fallback);

  static DateTime _toDate(dynamic v, DateTime fallback) {
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    final raw = _toStr(v);
    if (raw.isEmpty) return fallback;
    return DateTime.tryParse(raw) ?? fallback;
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return BookingModel(
      id: _toStr(json['id']),
      userId: _toStr(json['user_id']),
      eventId: _toStr(json['event_id']),
      eventTitle: _toStr(json['event_title'], 'Event'),
      eventDate: _toDate(json['event_date'], now),
      venue: _toStr(json['venue'], 'Venue TBD'),
      category: _toStr(json['category'], 'Event'),
      amount: _toDouble(json['amount']),
      status: _toStr(json['status'], 'confirmed'),
      ticketCode: _toStr(json['ticket_code'], 'EP-XXXXX'),
      imageUrl: json['image_url']?.toString(),
      createdAt: _toDate(json['created_at'], now),
      quantity: _toInt(json['quantity']),
      transactionId: json['transaction_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'event_id': eventId,
        'event_title': eventTitle,
        'event_date': eventDate.toIso8601String(),
        'venue': venue,
        'category': category,
        'amount': amount,
        'status': status,
        'ticket_code': ticketCode,
        'image_url': imageUrl,
        'created_at': createdAt.toIso8601String(),
        'quantity': quantity,
        'transaction_id': transactionId,
      };

  @override
  List<Object?> get props =>
      [id, userId, eventId, status, ticketCode, createdAt, transactionId];
}
