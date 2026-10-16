import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/review_model.dart';
import '../../auth/providers/auth_provider.dart';

// ── Reviews Provider ────────────────────────────────────────────
final reviewsProvider =
    AsyncNotifierProviderFamily<ReviewsNotifier, List<ReviewModel>, String>(
  ReviewsNotifier.new,
);

// ── Average rating provider ─────────────────────────────────────
final averageRatingProvider =
    Provider.family<AsyncValue<double>, String>((ref, eventId) {
  return ref.watch(reviewsProvider(eventId)).whenData((reviews) {
    if (reviews.isEmpty) return 0.0;
    return reviews.map((r) => r.rating).reduce((a, b) => a + b) /
        reviews.length;
  });
});

// ── Can User Review ─────────────────────────────────────────────
final canUserReviewProvider =
    Provider.family<bool, String>((ref, eventId) {
  final reviews = ref.watch(reviewsProvider(eventId)).valueOrNull ?? [];
  final user = ref.watch(authStateProvider).valueOrNull?.user;
  if (user == null) return false;
  return !reviews.any((r) => r.userId == user.id);
});

class ReviewsNotifier
    extends FamilyAsyncNotifier<List<ReviewModel>, String> {
  final _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  @override
  Future<List<ReviewModel>> build(String arg) async {
    return _fetchReviews(arg);
  }

  Future<List<ReviewModel>> _fetchReviews(String eventId) async {
    try {
      final snap = await _firestore
          .collection('reviews')
          .where('eventId', isEqualTo: eventId)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return ReviewModel.fromJson(data);
      }).toList();
    } catch (_) {
      // Return demo reviews when offline / collection doesn't exist
      return _demoReviews(eventId);
    }
  }

  Future<void> addReview({
    required String eventId,
    required double rating,
    required String comment,
    required String userName,
    String? userAvatar,
    String? userId,
  }) async {
    final id = _uuid.v4();
    final review = ReviewModel(
      id: id,
      eventId: eventId,
      userId: userId ?? 'anon',
      userName: userName,
      userAvatar: userAvatar,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
      isVerifiedAttendee: true,
    );
    try {
      await _firestore.collection('reviews').doc(id).set(review.toJson());
    } catch (_) {}
    final current = state.valueOrNull ?? [];
    state = AsyncData([review, ...current]);
  }

  Future<void> toggleLike(String reviewId, String userId) async {
    final current = state.valueOrNull ?? [];
    final idx = current.indexWhere((r) => r.id == reviewId);
    if (idx == -1) return;
    final review = current[idx];
    final liked = review.likes.contains(userId);
    final updated = review.copyWith(
      likes: liked
          ? (List<String>.from(review.likes)..remove(userId))
          : [...review.likes, userId],
    );
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'likes': updated.likes,
      });
    } catch (_) {}
    final list = List<ReviewModel>.from(current);
    list[idx] = updated;
    state = AsyncData(list);
  }

  static List<ReviewModel> _demoReviews(String eventId) {
    final now = DateTime.now();
    return [
      ReviewModel(
        id: 'demo1',
        eventId: eventId,
        userId: 'user1',
        userName: 'Sarah M.',
        rating: 5.0,
        comment:
            'Absolutely incredible event! The energy was unmatched and the performances were world-class. Will definitely attend next year!',
        createdAt: now.subtract(const Duration(days: 2)),
        likes: ['u2', 'u3', 'u4'],
        isVerifiedAttendee: true,
      ),
      ReviewModel(
        id: 'demo2',
        eventId: eventId,
        userId: 'user2',
        userName: 'James K.',
        rating: 4.5,
        comment:
            'Great organization, loved the venue layout. The food stalls had amazing variety. Lost one star because parking was chaotic.',
        createdAt: now.subtract(const Duration(days: 5)),
        likes: ['u1', 'u5'],
        isVerifiedAttendee: true,
      ),
      ReviewModel(
        id: 'demo3',
        eventId: eventId,
        userId: 'user3',
        userName: 'Amina W.',
        rating: 5.0,
        comment:
            "Best event I've been to in Nairobi in years. The production quality rivaled international concerts. Highly recommend!",
        createdAt: now.subtract(const Duration(days: 8)),
        likes: ['u1', 'u2', 'u6', 'u7'],
        isVerifiedAttendee: false,
      ),
    ];
  }
}
