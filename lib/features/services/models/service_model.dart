import 'package:equatable/equatable.dart';

class ServiceModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final String category;
  final double basePrice;
  final String priceRange;
  final String? imageUrl;
  final String? phone;
  final String? email;
  final double? rating;
  final int reviewCount;
  final bool isAvailable;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.basePrice,
    required this.priceRange,
    this.imageUrl,
    this.phone,
    this.email,
    this.rating,
    this.reviewCount = 0,
    this.isAvailable = true,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'].toString(), // Handle both string and int safely
      name: json['name'] as String? ?? 'Unknown Service',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0.0,
      priceRange: json['price_range'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['review_count'] as int? ?? 0,
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'base_price': basePrice,
        'price_range': priceRange,
        'image_url': imageUrl,
        'phone': phone,
        'email': email,
        'rating': rating,
        'review_count': reviewCount,
        'is_available': isAvailable,
      };

  @override
  List<Object?> get props => [id, name, category];
}
