import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

// ── Events List Provider ───────────────────────────────────
final eventsProvider = AsyncNotifierProvider<EventsNotifier, List<EventModel>>(
  EventsNotifier.new,
);

// ── Featured Events ────────────────────────────────────────
final featuredEventsProvider = Provider<AsyncValue<List<EventModel>>>((ref) {
  return ref
      .watch(eventsProvider)
      .whenData((events) => events.where((e) => e.isFeatured).toList());
});

// ── Category Filter ────────────────────────────────────────
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final filteredEventsProvider = Provider<AsyncValue<List<EventModel>>>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  return ref.watch(eventsProvider).whenData((events) {
    if (category == null) return events;
    return events.where((e) => e.category == category).toList();
  });
});

// ── Search Provider ────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');
final searchResultsProvider = Provider<AsyncValue<List<EventModel>>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase();
  return ref.watch(eventsProvider).whenData((events) {
    if (query.isEmpty) return events;
    return events.where((e) =>
        e.title.toLowerCase().contains(query) ||
        e.venue.toLowerCase().contains(query) ||
        e.category.toLowerCase().contains(query)).toList();
  });
});

// ── Single Event Provider ──────────────────────────────────
final singleEventProvider =
    FutureProvider.family<EventModel, String>((ref, id) async {
  try {
    final doc = await FirebaseFirestore.instance.collection('events').doc(id).get();
    if (!doc.exists) throw Exception('Event not found');
    final data = doc.data()!;
    data['id'] = doc.id;
    return EventModel.fromJson(data);
  } catch (e) {
    throw Exception('Failed to load event: $e');
  }
});

// ── Events Notifier ────────────────────────────────────────
class EventsNotifier extends AsyncNotifier<List<EventModel>> {
  @override
  Future<List<EventModel>> build() async {
    return _fetchEvents();
  }

  Future<List<EventModel>> _fetchEvents({String? category}) async {
    Query query = FirebaseFirestore.instance.collection('events');
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    
    var snapshot = await query.get();
    
    if (snapshot.docs.isEmpty && category == null) {
      await _seedDummyEvents();
      snapshot = await query.get();
    }

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return EventModel.fromJson(data);
    }).toList();
  }

  Future<void> _seedDummyEvents() async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    
    final dummyEvents = [
      {
        'title': 'Neon Nights Music Festival',
        'description': 'Experience the ultimate electric music festival under the stars.',
        'category': 'Music',
        'venue': 'Nairobi Expo Centre',
        'date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'price': 2500,
        'capacity': 5000,
        'booked_count': 1200,
        'image_url': 'https://images.unsplash.com/photo-1540039155732-6762b5134fb3?q=80&w=1200&auto=format&fit=crop',
        'organizer_id': 'admin',
        'organizer_name': 'EventPro Live',
        'is_featured': true,
      },
      {
        'title': 'Tech Disrupt Summit 2026',
        'description': 'The biggest tech conference in East Africa featuring top founders and AI experts.',
        'category': 'Conference',
        'venue': 'KICC, Nairobi',
        'date': DateTime.now().add(const Duration(days: 14)).toIso8601String(),
        'price': 5000,
        'capacity': 1000,
        'booked_count': 850,
        'image_url': 'https://images.unsplash.com/photo-1505373877841-8d25f7d46678?q=80&w=1200&auto=format&fit=crop',
        'organizer_id': 'admin',
        'organizer_name': 'Tech Hub KE',
        'is_featured': true,
      },
      {
        'title': 'Laugh Out Loud Comedy Show',
        'description': 'An evening of non-stop laughter with the best comedians in town.',
        'category': 'Comedy',
        'venue': 'National Theatre',
        'date': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'price': 1500,
        'capacity': 400,
        'booked_count': 300,
        'image_url': 'https://images.unsplash.com/photo-1585699324551-f6c309eedeca?q=80&w=1200&auto=format&fit=crop',
        'organizer_id': 'admin',
        'organizer_name': 'Laugh Industry',
        'is_featured': false,
      },
      {
        'title': 'Gourmet Food Tasting & Wine',
        'description': 'A premium food tasting event featuring top chefs and exclusive wine pairings.',
        'category': 'Food',
        'venue': 'Windsor Golf Hotel',
        'date': DateTime.now().add(const Duration(days: 21)).toIso8601String(),
        'price': 8000,
        'capacity': 200,
        'booked_count': 180,
        'image_url': 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?q=80&w=1200&auto=format&fit=crop',
        'organizer_id': 'admin',
        'organizer_name': 'Gourmet KE',
        'is_featured': true,
      },
      {
        'title': 'Kenya Rift Valley Marathon',
        'description': 'A scenic full and half marathon through the Great Rift Valley. Runners kit and medals included.',
        'category': 'Sports',
        'venue': 'Bomet Town Grounds',
        'date': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'price': 1200,
        'capacity': 3000,
        'booked_count': 640,
        'image_url': 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?q=80&w=1200&auto=format&fit=crop',
        'organizer_id': 'admin',
        'organizer_name': 'Athletics KE',
        'is_featured': false,
      },
      {
        'title': 'Nairobi AI & Robotics Expo',
        'description': 'Hands-on demos, workshops and keynotes on the future of AI, automation and robotics in Africa.',
        'category': 'Tech',
        'venue': 'Gigiri River Park',
        'date': DateTime.now().add(const Duration(days: 18)).toIso8601String(),
        'price': 3000,
        'capacity': 800,
        'booked_count': 210,
        'image_url': 'https://images.unsplash.com/photo-1518770660439-463619050423?q=80&w=1200&auto=format&fit=crop',
        'organizer_id': 'admin',
        'organizer_name': 'Tech Hub KE',
        'is_featured': true,
      },
      {
        'title': 'East African Art & Craft Fair',
        'description': 'Celebrate local talent with live paintings, sculpture, textiles and craft markets from across the region.',
        'category': 'Art',
        'venue': 'Goethe House, Nairobi',
        'date': DateTime.now().add(const Duration(days: 10)).toIso8601String(),
        'price': 500,
        'capacity': 600,
        'booked_count': 150,
        'image_url': 'https://images.unsplash.com/photo-1460661419291-866e9845b612?q=80&w=1200&auto=format&fit=crop',
        'organizer_id': 'admin',
        'organizer_name': 'Soka Art Collective',
        'is_featured': false,
      },
      {
        'title': 'Sauti Live Concert Series',
        'description': 'An open-air night showcasing top Benglie, Afrobeats and Gengetone artists on one stage.',
        'category': 'Music',
        'venue': 'Carnivore Grounds',
        'date': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
        'price': 2000,
        'capacity': 4000,
        'booked_count': 1850,
        'image_url': 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?q=80&w=1200&auto=format&fit=crop',
        'organizer_id': 'admin',
        'organizer_name': 'EventPro Live',
        'is_featured': true,
      },
      {
        'title': 'Nairobi Street Food Festival',
        'description': 'A fun-filled weekend of mtindi, mishkaki, viazi karai and more from the city\'s best street vendors.',
        'category': 'Food',
        'venue': 'Kenyatta Market Car Park',
        'date': DateTime.now().add(const Duration(days: 12)).toIso8601String(),
        'price': 800,
        'capacity': 1500,
        'booked_count': 430,
        'image_url': 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=1200&auto=format&fit=crop',
        'organizer_id': 'admin',
        'organizer_name': 'Gourmet KE',
        'is_featured': false,
      }
    ];

    for (var event in dummyEvents) {
      final docRef = firestore.collection('events').doc();
      batch.set(docRef, event);
    }
    
    await batch.commit();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchEvents());
  }
}
