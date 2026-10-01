import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../../auth/providers/auth_provider.dart';

// ── Bookings Provider ──────────────────────────────────────────────────────
final bookingsProvider =
    AsyncNotifierProvider<BookingsNotifier, List<BookingModel>>(
  BookingsNotifier.new,
);

// ── Status Filter ──────────────────────────────────────────────────────────
final bookingStatusFilterProvider = StateProvider<String?>((ref) => null);

final filteredBookingsProvider =
    Provider<AsyncValue<List<BookingModel>>>((ref) {
  final status = ref.watch(bookingStatusFilterProvider);
  return ref.watch(bookingsProvider).whenData((bookings) {
    if (status == null) return bookings;
    return bookings.where((b) => b.status == status).toList();
  });
});

// ── Notifier ───────────────────────────────────────────────────────────────
class BookingsNotifier extends AsyncNotifier<List<BookingModel>> {
  @override
  Future<List<BookingModel>> build() async {
    final userId = ref.watch(authStateProvider).valueOrNull?.user?.id;
    if (userId == null) return [];
    return _fetchBookings(userId);
  }

  Future<List<BookingModel>> _fetchBookings(String userId) async {
    final firestore = FirebaseFirestore.instance;
    // NOTE: Filtering on `user_id` and sorting on `created_at` together would
    // require a composite index in Firestore. To avoid that, we only filter
    // server-side and sort the (small) result list client-side.
    var snapshot = await firestore
        .collection('bookings')
        .where('user_id', isEqualTo: userId)
        .get();

    // Seed dummy bookings if empty (for demo)
    if (snapshot.docs.isEmpty) {
      await _seedDummyBookings(userId);
      snapshot = await firestore
          .collection('bookings')
          .where('user_id', isEqualTo: userId)
          .get();
    }

    final bookings = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return BookingModel.fromJson(data);
    }).toList();

    bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return bookings;
  }

  Future<void> _seedDummyBookings(String userId) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    final dummies = [
      {
        'user_id': userId,
        'event_id': 'event_001',
        'event_title': 'Neon Nights Music Festival',
        'event_date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'venue': 'Nairobi Expo Centre',
        'category': 'Music',
        'amount': 2500.0,
        'status': 'confirmed',
        'ticket_code': 'EP-MF-${userId.substring(0, 6).toUpperCase()}',
        'image_url':
            'https://images.unsplash.com/photo-1540039155732-6762b5134fb3?q=80&w=800&auto=format&fit=crop',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 2))
            .toIso8601String(),
        'quantity': 1,
      },
      {
        'user_id': userId,
        'event_id': 'event_002',
        'event_title': 'Tech Disrupt Summit 2026',
        'event_date':
            DateTime.now().add(const Duration(days: 14)).toIso8601String(),
        'venue': 'KICC, Nairobi',
        'category': 'Conference',
        'amount': 5000.0,
        'status': 'confirmed',
        'ticket_code': 'EP-TC-${userId.substring(0, 6).toUpperCase()}',
        'image_url':
            'https://images.unsplash.com/photo-1505373877841-8d25f7d46678?q=80&w=800&auto=format&fit=crop',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 5))
            .toIso8601String(),
        'quantity': 2,
      },
      {
        'user_id': userId,
        'event_id': 'event_003',
        'event_title': 'Gourmet Food Tasting & Wine',
        'event_date': DateTime.now()
            .subtract(const Duration(days: 30))
            .toIso8601String(),
        'venue': 'Windsor Golf Hotel',
        'category': 'Food',
        'amount': 8000.0,
        'status': 'attended',
        'ticket_code': 'EP-FW-${userId.substring(0, 6).toUpperCase()}',
        'image_url':
            'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?q=80&w=800&auto=format&fit=crop',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 35))
            .toIso8601String(),
        'quantity': 1,
      },
      {
        'user_id': userId,
        'event_id': 'event_004',
        'event_title': 'Laugh Out Loud Comedy Show',
        'event_date': DateTime.now()
            .subtract(const Duration(days: 10))
            .toIso8601String(),
        'venue': 'National Theatre',
        'category': 'Comedy',
        'amount': 1500.0,
        'status': 'cancelled',
        'ticket_code': 'EP-CS-${userId.substring(0, 6).toUpperCase()}',
        'image_url':
            'https://images.unsplash.com/photo-1585699324551-f6c309eedeca?q=80&w=800&auto=format&fit=crop',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 15))
            .toIso8601String(),
        'quantity': 1,
      },
    ];

    for (final booking in dummies) {
      final docRef = firestore.collection('bookings').doc();
      batch.set(docRef, booking);
    }

    await batch.commit();
  }

  Future<void> refresh() async {
    final userId = ref.read(authStateProvider).valueOrNull?.user?.id;
    if (userId == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchBookings(userId));
  }
}
