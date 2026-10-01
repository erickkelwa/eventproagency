import 'package:equatable/equatable.dart';

class EventModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final String venue;
  final String? address;
  final DateTime date;
  final double price;
  final int capacity;
  final int? bookedCount;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String organizerId;
  final String? organizerName;
  final bool isFeatured;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.venue,
    this.address,
    required this.date,
    required this.price,
    required this.capacity,
    this.bookedCount,
    this.imageUrl,
    this.latitude,
    this.longitude,
    required this.organizerId,
    this.organizerName,
    this.isFeatured = false,
  });

  int get availableSlots => capacity - (bookedCount ?? 0);
  bool get isSoldOut => availableSlots <= 0;
  bool get isFree => price == 0;
  String get formattedPrice => isFree ? 'Free' : 'KES ${price.toStringAsFixed(0)}';

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      venue: json['venue'] as String,
      address: json['address'] as String?,
      date: json['date'] is String ? DateTime.parse(json['date']) : (json['date'] as dynamic).toDate(),
      price: (json['price'] as num).toDouble(),
      capacity: json['capacity'] as int,
      bookedCount: json['booked_count'] as int?,
      imageUrl: json['image_url'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      organizerId: json['organizer_id'] as String,
      organizerName: json['organizer_name'] as String?,
      isFeatured: json['is_featured'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'venue': venue,
        'address': address,
        'date': date.toIso8601String(),
        'price': price,
        'capacity': capacity,
        'booked_count': bookedCount,
        'image_url': imageUrl,
        'latitude': latitude,
        'longitude': longitude,
        'organizer_id': organizerId,
        'organizer_name': organizerName,
        'is_featured': isFeatured,
      };

  @override
  List<Object?> get props => [id, title, date, price, category];
}
