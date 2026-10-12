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
    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return EventModel.fromJson(data);
    }
  } catch (_) {
    // Continue to fallback check
  }

  // Look in curated rich events
  final curated = EventsNotifier.getCuratedEvents();
  final match = curated.where((e) => e.id == id).firstOrNull;
  if (match != null) return match;

  throw Exception('Event not found');
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
    
    try {
      var snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return EventModel.fromJson(data);
        }).toList();
      }
    } catch (_) {
      // Fallback to rich curated local dataset if offline or Firestore empty
    }

    // Curated rich events with full descriptions and main guests
    final dummy = getCuratedEvents();
    if (category == null) return dummy;
    return dummy.where((e) => e.category.toLowerCase() == category.toLowerCase()).toList();
  }

  static List<EventModel> getCuratedEvents() {
    final now = DateTime.now();
    return [
      EventModel(
        id: 'sol-fest-2026',
        title: 'Sol Fest Africa 2026: The Grand Reunion',
        description: 'East Africa’s premier live concert experience returning bigger than ever! Featuring high-energy performances from Sauti Sol, Bien-Aimé, Nyashinski, and surprise international Afrobeats superstars. Expect state-of-the-art stage pyrotechnics, immersive 3D surround sound, curated artisan cocktail lounges, and an electric crowd celebrating authentic African music culture.',
        category: 'Music',
        venue: 'Uhuru Gardens Arena, Nairobi',
        address: 'Langata Rd, Nairobi, Kenya',
        date: now.add(const Duration(days: 6, hours: 4)),
        price: 3500,
        capacity: 12000,
        bookedCount: 8400,
        imageUrl: 'https://images.unsplash.com/photo-1540039155732-6762b5134fb3?q=80&w=1200&auto=format&fit=crop',
        latitude: -1.3262,
        longitude: 36.7865,
        organizerId: 'sol_generation',
        organizerName: 'Sol Generation & EventPro',
        isFeatured: true,
        guests: ['Sauti Sol', 'Bien-Aimé', 'Nyashinski', 'Tiwa Savage', 'Nadia Mukami'],
        highlights: ['360-Degree Revolving Main Stage', 'VIP Backstage Meet & Greet', 'Gourmet Food Village', 'Express Fast-Track M-Pesa Gate'],
      ),
      EventModel(
        id: 'nairobi-tech-summit-2026',
        title: 'Nairobi Global Tech Summit & AI Expo',
        description: 'The epicenter of African innovation. Connect with over 150 Silicon Valley and African VCs, top tech founders, and AI engineers. Deep dive into building real-world AI applications, fintech cross-border rails, sovereign cloud computing, and startup growth hacking. Includes high-stakes live pitch battles with over KES 10,000,000 in seed grants.',
        category: 'Tech',
        venue: 'KICC Tsavo Ballroom, Nairobi',
        address: 'Harambee Ave, Nairobi CBD',
        date: now.add(const Duration(days: 12, hours: 2)),
        price: 5000,
        capacity: 2500,
        bookedCount: 1980,
        imageUrl: 'https://images.unsplash.com/photo-1505373877841-8d25f7d46678?q=80&w=1200&auto=format&fit=crop',
        latitude: -1.2884,
        longitude: 36.8233,
        organizerId: 'tech_ventures',
        organizerName: 'East Africa Tech Hub',
        isFeatured: true,
        guests: ['Dr. Bitange Ndemo (Ambassador)', 'Hilda Moraa (Pezesha CEO)', 'Sam Altman (Keynote Virtual)', 'Iyinoluwa Aboyeji (Future Africa)'],
        highlights: ['Pitch Stage & Seed Fund Competition', 'Exclusive Founders Lounge Access', 'AI Hands-on Sandbox Labs', 'Official After-Party Networking'],
      ),
      EventModel(
        id: 'blankets-and-wine-fest',
        title: 'Blankets & Wine: Afro-Fusion Festival',
        description: 'The legendary urban picnic and lifestyle music festival. Bring your picnic mats, trendy sunglasses, and best vibes for an afternoon of live acoustic soul, nu-afrobeats, fine wines, and artisanal pop-up craft shops under the Nairobi sun.',
        category: 'Music',
        venue: 'Laurens Garden, Karen',
        address: 'Karen Rd, Nairobi',
        date: now.add(const Duration(days: 9)),
        price: 3000,
        capacity: 6000,
        bookedCount: 4120,
        imageUrl: 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?q=80&w=1200&auto=format&fit=crop',
        latitude: -1.3340,
        longitude: 36.7118,
        organizerId: 'muthoni_drummer',
        organizerName: 'Blankets & Wine Experience',
        isFeatured: true,
        guests: ['Muthoni Drummer Queen', 'Karun', 'Fena Gitu', 'Blinky Bill', 'DJ Dii'],
        highlights: ['Sunset Picnic Lawn', 'Artisan Craft Fair', 'Curated Wine & Sangria Bar', 'Silent Disco After-Party'],
      ),
      EventModel(
        id: 'laugh-champions-live',
        title: 'Kings of Comedy Live Gala 2026',
        description: 'Nairobi’s biggest stand-up comedy showdown! Unfiltered jokes, hilarious storytelling, and celebrity roasts guaranteed to have you rolling on the floor with laughter. Featuring the most iconic comedy veterans and viral internet personalities.',
        category: 'Comedy',
        venue: 'Kenya National Theatre',
        address: 'Harry Thuku Rd, Nairobi',
        date: now.add(const Duration(days: 4, hours: 3)),
        price: 2000,
        capacity: 850,
        bookedCount: 650,
        imageUrl: 'https://images.unsplash.com/photo-1585699324551-f6c309eedeca?q=80&w=1200&auto=format&fit=crop',
        latitude: -1.2789,
        longitude: 36.8166,
        organizerId: 'laugh_industry',
        organizerName: 'Laugh Industry Productions',
        isFeatured: false,
        guests: ['Churchill (Daniel Ndambuki)', 'Eric Omondi', 'Mammito Eunice', 'MC Jessy', 'Flaqo Raz'],
        highlights: ['Red Carpet Celebrity Arrivals', 'Live Band Comedy Interludes', 'VIP Front Row Seating', 'Complimentary Welcome Drinks'],
      ),
      EventModel(
        id: 'gourmet-wine-safari',
        title: 'Gourmet Nairobi: Chef Tasting & Wine Tour',
        description: 'An ultra-exclusive fine-dining culinary showcase. Five award-winning Michelin-trained executive chefs prepare a 7-course safari tasting menu harmoniously paired with rare vintage wines from Stellenbosch and Bordeaux.',
        category: 'Food',
        venue: 'Windsor Golf Hotel & Country Club',
        address: 'Kigwa Lane, Ridgeways, Nairobi',
        date: now.add(const Duration(days: 15, hours: 5)),
        price: 8500,
        capacity: 250,
        bookedCount: 195,
        imageUrl: 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?q=80&w=1200&auto=format&fit=crop',
        latitude: -1.2215,
        longitude: 36.8624,
        organizerId: 'gourmet_east_africa',
        organizerName: 'Epicurean Guild Kenya',
        isFeatured: true,
        guests: ['Chef Ali Mandhry', 'Chef Kiran Jethwa', 'Master Sommelier Jean Dupont', 'Pastry Chef Amina Bello'],
        highlights: ['7-Course Safari Degustation', 'Private Wine Sommelier Pairing', 'Live Jazz Quartet', 'Gift Box of Artisanal Truffles'],
      ),
      EventModel(
        id: 'safari-rally-rift-valley',
        title: 'Great Rift Valley Offroad Rally & Festival',
        description: 'Adrenaline-pumping motorsports action! Watch super-tuned 4x4 rally beasts and buggies tear through dramatic volcanic hills, mud stages, and dust bowls. Includes an open paddock pit walk and a sunset DJ stage.',
        category: 'Sports',
        venue: 'Soysambu Wildlife Conservancy, Naivasha',
        address: 'Naivasha - Nakuru Hwy, Kenya',
        date: now.add(const Duration(days: 20, hours: 1)),
        price: 2500,
        capacity: 7500,
        bookedCount: 3800,
        imageUrl: 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?q=80&w=1200&auto=format&fit=crop',
        latitude: -0.4728,
        longitude: 36.2731,
        organizerId: 'motorsport_ke',
        organizerName: 'Kenya Motorsport Federation',
        isFeatured: false,
        guests: ['Carl Tundo (Rally Legend)', 'Karan Patel (African Champion)', 'Maxine Wahome', 'McRae Kimathi'],
        highlights: ['Spectator Hill Stage View', 'Paddock Pit Lane Access', 'Offroad 4x4 Passenger Ride-alongs', 'Sunset Campfire & BBQ'],
      ),
      EventModel(
        id: 'east-african-art-collective',
        title: 'Nairobi Contemporary Art Fair & Gallery Night',
        description: 'Explore over 200 striking original paintings, avant-garde bronze sculptures, and cutting-edge digital media art installations from East and Central Africa’s most visionary contemporary creators.',
        category: 'Art',
        venue: 'Nairobi National Museum Gallery',
        address: 'Museum Hill, Kipande Rd, Nairobi',
        date: now.add(const Duration(days: 11, hours: 2)),
        price: 1000,
        capacity: 1200,
        bookedCount: 480,
        imageUrl: 'https://images.unsplash.com/photo-1460661419291-866e9845b612?q=80&w=1200&auto=format&fit=crop',
        latitude: -1.2739,
        longitude: 36.8148,
        organizerId: 'art_collective_ke',
        organizerName: 'Kuona Arts Trust',
        isFeatured: false,
        guests: ['Michael Soi (Visual Artist)', 'Peterson Kamwathi', 'Wambui Collymore', 'Beatrice Wanjiku'],
        highlights: ['Curator-Led Art Walk', 'Live Canvas Painting by Master Artists', 'Art Auction Benefiting Youth Programs', 'Champagne Reception'],
      ),
    ];
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchEvents());
  }
}
