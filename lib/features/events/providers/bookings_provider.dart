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
    final snapshot = await firestore
        .collection('bookings')
        .where('user_id', isEqualTo: userId)
        .get();

    final bookings = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return BookingModel.fromJson(data);
    }).toList();

    // Defence in depth: a shared device can hand back a doc whose user_id got
    // written by an older build. Never render tickets that are not this user's.
    bookings.removeWhere((b) => b.userId != userId);

    bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return bookings;
  }

  /// Issue the paid ticket into the SIGNED-IN user's own bookings.
  ///
  /// Called once a payment reaches `completed`. The document id is derived from
  /// the Firebase uid + payment reference, so re-polling the same payment can
  /// never create a second ticket, and the ticket can only ever be read back by
  /// the same account (see the `user_id` filter in [_fetchBookings]).
  /// Returns the ticket code, or null when there is nothing to issue.
  Future<String?> issueTicket({
    required String bookingType,
    required String itemId,
    required String transactionId,
    required double amount,
    int quantity = 1,
    String? itemTitle,
    String? eventDate,
    String? venue,
    String? category,
    String? imageUrl,
  }) async {
    final userId = ref.read(authStateProvider).valueOrNull?.user?.id;
    if (userId == null || userId.isEmpty) return null;
    if (transactionId.isEmpty) return null;

    final firestore = FirebaseFirestore.instance;
    final docId = '${userId}_$transactionId';
    final docRef = firestore.collection('bookings').doc(docId);

    // Already issued (this screen can be rebuilt several times while polling).
    final existing = await docRef.get();
    if (existing.exists) {
      await refresh();
      return BookingModel.fromJson({
        ...existing.data()!,
        'id': docRef.id,
      }).ticketCode;
    }

    final now = DateTime.now();
    final isEvent = bookingType == 'event';
    final title = (itemTitle != null && itemTitle.trim().isNotEmpty)
        ? itemTitle.trim()
        : (isEvent ? 'Event Ticket #$itemId' : 'Service Booking #$itemId');
    final ticketCode =
        'EP-${(isEvent ? 'TKT' : 'SRV')}-${transactionId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')}';

    final data = <String, dynamic>{
      'user_id': userId,
      'event_id': itemId,
      'event_title': title,
      'event_date': eventDate ?? now.toIso8601String(),
      'venue': venue ?? 'To be announced',
      'category': category ?? (isEvent ? 'Event' : 'Service'),
      'amount': amount,
      'status': 'confirmed',
      'ticket_code': ticketCode,
      'image_url': imageUrl,
      'created_at': now.toIso8601String(),
      'quantity': quantity < 1 ? 1 : quantity,
      'transaction_id': transactionId,
      'booking_type': bookingType,
    };

    await docRef.set(data);

    // Keep the in-memory list in sync so "My Tickets" shows it immediately.
    final current = state.valueOrNull ?? <BookingModel>[];
    final ticket = BookingModel.fromJson({...data, 'id': docId});
    final merged = [...current.where((b) => b.id != docId), ticket]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = AsyncData(merged);

    return ticketCode;
  }

  Future<void> refresh() async {
    final userId = ref.read(authStateProvider).valueOrNull?.user?.id;
    if (userId == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchBookings(userId));
  }
}
