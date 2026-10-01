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
  });

  bool get isUpcoming => eventDate.isAfter(DateTime.now()) && status != 'cancelled';
  bool get isPast => eventDate.isBefore(DateTime.now()) || status == 'attended';
  bool get isCancelled => status == 'cancelled';
  bool get isConfirmed => status == 'confirmed';

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      eventId: json['event_id'] as String,
      eventTitle: json['event_title'] as String,
      eventDate: DateTime.parse(json['event_date'] as String),
      venue: json['venue'] as String,
      category: json['category'] as String? ?? 'Event',
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'confirmed',
      ticketCode: json['ticket_code'] as String? ?? 'EP-XXXXX',
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      quantity: json['quantity'] as int? ?? 1,
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
      };

  @override
  List<Object?> get props =>
      [id, userId, eventId, status, ticketCode, createdAt];
}
