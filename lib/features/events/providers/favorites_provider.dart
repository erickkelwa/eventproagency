import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';
import 'events_provider.dart';

// ── Favorites IDs ───────────────────────────────────────────────
final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, Set<String>>(
  FavoritesNotifier.new,
);

// ── Derived: full EventModel list of favorites ──────────────────
final favoriteEventsProvider =
    Provider<AsyncValue<List<EventModel>>>((ref) {
  final ids = ref.watch(favoritesProvider).valueOrNull ?? {};
  return ref.watch(eventsProvider).whenData(
    (events) => events.where((e) => ids.contains(e.id)).toList(),
  );
});

// ── Is a specific event favorited ──────────────────────────────
final isFavoriteProvider = Provider.family<bool, String>((ref, eventId) {
  final ids = ref.watch(favoritesProvider).valueOrNull ?? {};
  return ids.contains(eventId);
});

class FavoritesNotifier extends AsyncNotifier<Set<String>> {
  static const _key = 'eventpro_favorites';

  @override
  Future<Set<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.toSet();
  }

  Future<bool> toggle(String eventId) async {
    final current = state.valueOrNull ?? {};
    final isFav = current.contains(eventId);
    final updated = isFav
        ? (Set<String>.from(current)..remove(eventId))
        : {...current, eventId};
    state = AsyncData(updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated.toList());
    return !isFav; // returns new isFavorite state
  }

  Future<void> clear() async {
    state = const AsyncData({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
