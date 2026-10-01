import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';

// ── Services List Provider ─────────────────────────────────
final servicesProvider =
    AsyncNotifierProvider<ServicesNotifier, List<ServiceModel>>(
  ServicesNotifier.new,
);

// ── Category Filter ────────────────────────────────────────
final selectedServiceCategoryProvider = StateProvider<String?>((ref) => null);

final filteredServicesProvider =
    Provider<AsyncValue<List<ServiceModel>>>((ref) {
  final category = ref.watch(selectedServiceCategoryProvider);
  return ref.watch(servicesProvider).whenData((services) {
    if (category == null) return services;
    return services.where((s) => s.category == category).toList();
  });
});

// ── Single Service Provider ────────────────────────────────
final singleServiceProvider =
    FutureProvider.family<ServiceModel, String>((ref, id) async {
  final doc =
      await FirebaseFirestore.instance.collection('services').doc(id).get();
  if (!doc.exists) throw Exception('Service not found');
  final data = doc.data()!;
  data['id'] = doc.id;
  return ServiceModel.fromJson(data);
});

// ── Services Notifier ──────────────────────────────────────
class ServicesNotifier extends AsyncNotifier<List<ServiceModel>> {
  @override
  Future<List<ServiceModel>> build() async {
    return _fetch();
  }

  Future<List<ServiceModel>> _fetch() async {
    final firestore = FirebaseFirestore.instance;
    var snapshot = await firestore.collection('services').get();

    // Seed demo data if empty
    if (snapshot.docs.isEmpty) {
      await _seedDemoServices();
      snapshot = await firestore.collection('services').get();
    }

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return ServiceModel.fromJson(data);
    }).toList();
  }

  Future<void> _seedDemoServices() async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    final demoServices = [
      {
        'name': 'Elite Catering & Cuisine',
        'description':
            'Premium catering services for all event types. Buffet, plated, cocktail — we do it all with 5-star quality.',
        'category': 'Catering',
        'price_range': 'KES 3,500 – 12,000 per head',
        'base_price': 3500,
        'rating': 4.8,
        'review_count': 124,
        'is_available': true,
        'image_url':
            'https://images.unsplash.com/photo-1555244162-803834f70033?q=80&w=800&auto=format&fit=crop',
        'vendor_name': 'Chef Masters KE',
        'location': 'Nairobi, Kenya',
        'tags': ['Buffet', 'Plated', 'Cocktail', 'Dietary options'],
      },
      {
        'name': 'Pro Lens Photography',
        'description':
            'Award-winning event photography and cinematography. We capture memories that last forever.',
        'category': 'Photography',
        'price_range': 'KES 25,000 – 80,000',
        'base_price': 25000,
        'rating': 4.9,
        'review_count': 89,
        'is_available': true,
        'image_url':
            'https://images.unsplash.com/photo-1554048612-b6a482bc67e5?q=80&w=800&auto=format&fit=crop',
        'vendor_name': 'Focus Studio KE',
        'location': 'Nairobi, Kenya',
        'tags': ['Photography', 'Videography', 'Drone shots', '4K video'],
      },
      {
        'name': 'Sentinel Security Solutions',
        'description':
            'Professional licensed security personnel for events of all sizes. Crowd control, VIP protection and more.',
        'category': 'Security',
        'price_range': 'KES 8,000 – 30,000',
        'base_price': 8000,
        'rating': 4.6,
        'review_count': 67,
        'is_available': true,
        'image_url':
            'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?q=80&w=800&auto=format&fit=crop',
        'vendor_name': 'Sentinel KE',
        'location': 'Nairobi, Kenya',
        'tags': ['Crowd control', 'VIP escort', 'CCTV', 'Uniformed guards'],
      },
      {
        'name': 'VVIP Executive Transport',
        'description':
            'Luxury fleet for guest transfers, VIP pickups and event shuttle services across Nairobi.',
        'category': 'Transport',
        'price_range': 'KES 5,000 – 50,000',
        'base_price': 5000,
        'rating': 4.7,
        'review_count': 43,
        'is_available': true,
        'image_url':
            'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?q=80&w=800&auto=format&fit=crop',
        'vendor_name': 'Prestige Moves KE',
        'location': 'Nairobi, Kenya',
        'tags': ['Limo', 'SUV', 'Shuttle bus', 'Airport transfer'],
      },
      {
        'name': 'Dream Décor & Florals',
        'description':
            'Transform any venue into a breathtaking space. Floral arrangements, draping, lighting and themed setups.',
        'category': 'Decoration',
        'price_range': 'KES 15,000 – 200,000',
        'base_price': 15000,
        'rating': 4.9,
        'review_count': 156,
        'is_available': true,
        'image_url':
            'https://images.unsplash.com/photo-1478146896981-b80fe463b330?q=80&w=800&auto=format&fit=crop',
        'vendor_name': 'Blooms & Beyond',
        'location': 'Nairobi, Kenya',
        'tags': ['Floral', 'Draping', 'Themed décor', 'Lighting'],
      },
      {
        'name': 'Stellar Sound & Light',
        'description':
            'Professional PA systems, LED walls, stage lighting and DJ equipment for concerts and corporate events.',
        'category': 'Sound & Lighting',
        'price_range': 'KES 20,000 – 150,000',
        'base_price': 20000,
        'rating': 4.7,
        'review_count': 92,
        'is_available': true,
        'image_url':
            'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?q=80&w=800&auto=format&fit=crop',
        'vendor_name': 'Stellar Audio KE',
        'location': 'Nairobi, Kenya',
        'tags': ['PA system', 'LED wall', 'Stage lights', 'DJ booth'],
      },
      {
        'name': 'Live Entertainment Hub',
        'description':
            'Bands, DJs, MCs, dancers, comedians and cultural performers — one booking, unforgettable entertainment.',
        'category': 'Entertainment',
        'price_range': 'KES 10,000 – 120,000',
        'base_price': 10000,
        'rating': 4.8,
        'review_count': 78,
        'is_available': true,
        'image_url':
            'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?q=80&w=800&auto=format&fit=crop',
        'vendor_name': 'Stage One KE',
        'location': 'Nairobi, Kenya',
        'tags': ['Live band', 'DJ', 'MC', 'Dancers', 'Comedian'],
      },
    ];

    for (final service in demoServices) {
      final docRef = firestore.collection('services').doc();
      batch.set(docRef, service);
    }

    await batch.commit();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

// ── Service Booking Provider ───────────────────────────────
final serviceBookingProvider =
    StateNotifierProvider<ServiceBookingNotifier, ServiceBookingState>(
  (ref) => ServiceBookingNotifier(),
);

class ServiceBookingState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? booking;

  const ServiceBookingState({
    this.isLoading = false,
    this.error,
    this.booking,
  });
}

class ServiceBookingNotifier extends StateNotifier<ServiceBookingState> {
  ServiceBookingNotifier() : super(const ServiceBookingState());

  Future<Map<String, dynamic>?> book({
    required String serviceId,
    required String eventDate,
    required String notes,
  }) async {
    state = const ServiceBookingState(isLoading: true);
    
    // Simulate network delay for demo
    await Future.delayed(const Duration(seconds: 1));
    
    try {
      final booking = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'service_id': serviceId,
        'event_date': eventDate,
        'notes': notes,
        'status': 'pending',
      };
      
      // Save demo booking to Firestore
      await FirebaseFirestore.instance
          .collection('service_bookings')
          .doc(booking['id'])
          .set(booking);
          
      state = ServiceBookingState(booking: booking);
      return booking;
    } catch (e) {
      state = ServiceBookingState(error: e.toString());
      return null;
    }
  }
}
