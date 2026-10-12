import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage {
  en('English', 'EN', '🇺🇸'),
  sw('Kiswahili', 'SW', '🇰🇪'),
  fr('Français', 'FR', '🇫🇷');

  final String title;
  final String code;
  final String flag;
  const AppLanguage(this.title, this.code, this.flag);
}

final languageProvider = StateProvider<AppLanguage>((ref) => AppLanguage.en);

class AppStrings {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'EventPro',
      'tagline': 'Experience Live Moments',
      'discover_events': 'Discover Events',
      'popular_categories': 'Popular Categories',
      'featured_events': 'Featured Events',
      'upcoming_events': 'Upcoming Events',
      'search_placeholder': 'Search events, artists, venues...',
      'all': 'All',
      'book_tickets': 'Book Tickets',
      'sold_out': 'Sold Out',
      'free': 'Free',
      'venue': 'Venue',
      'date': 'Date',
      'time': 'Time',
      'available': 'Available',
      'about_event': 'About this Event',
      'special_guests': 'Special Guests & Performers',
      'vip_perks': 'VIP & Premium Perks',
      'get_directions': 'Get Directions',
      'organizer': 'Organizer',
      'nearby_map': 'Nearby Events Map',
      'digital_tickets': 'My Digital Tickets',
      'vendors_services': 'Vendors & Services',
      'notifications': 'Notifications',
      'switch_language': 'Language',
      'welcome_back': 'Welcome Back',
      'welcome_new': 'Welcome to EventPro!',
      'explore_now': 'Explore Now',
    },
    'sw': {
      'app_name': 'EventPro',
      'tagline': 'Shuhudia Matukio Mubashara',
      'discover_events': 'Gundua Matukio',
      'popular_categories': 'Aina Maarufu',
      'featured_events': 'Matukio Maalum',
      'upcoming_events': 'Matukio Yajayo',
      'search_placeholder': 'Tafuta matukio, wasanii, kumbi...',
      'all': 'Yote',
      'book_tickets': 'Nunua Tiketi',
      'sold_out': 'Tiketi Zimeisha',
      'free': 'Bure',
      'venue': 'Ukumbi',
      'date': 'Tarehe',
      'time': 'Muda',
      'available': 'Zilizopo',
      'about_event': 'Kuhusu Tukio Hili',
      'special_guests': 'Wageni Mashuhuri & Wasanii',
      'vip_perks': 'Huduma Maalum za VIP',
      'get_directions': 'Pata Maelekezo ya Ramani',
      'organizer': 'Mwandalizi',
      'nearby_map': 'Ramani ya Matukio ya Karibu',
      'digital_tickets': 'Tiketi Zangu za Kidijitali',
      'vendors_services': 'Huduma na Watoa Huduma',
      'notifications': 'Arifa',
      'switch_language': 'Lugha',
      'welcome_back': 'Karibu Tena',
      'welcome_new': 'Karibu sana EventPro!',
      'explore_now': 'Gundua Sasa',
    },
    'fr': {
      'app_name': 'EventPro',
      'tagline': 'Vivez des Moments Uniques',
      'discover_events': 'Découvrir des Événements',
      'popular_categories': 'Catégories Populaires',
      'featured_events': 'Événements en Vedette',
      'upcoming_events': 'Événements à Venir',
      'search_placeholder': 'Rechercher artistes, lieux, concerts...',
      'all': 'Tout',
      'book_tickets': 'Réserver',
      'sold_out': 'Complet',
      'free': 'Gratuit',
      'venue': 'Lieu',
      'date': 'Date',
      'time': 'Heure',
      'available': 'Disponibles',
      'about_event': 'À propos de cet événement',
      'special_guests': 'Invités Spéciaux & Artistes',
      'vip_perks': 'Avantages VIP & Premium',
      'get_directions': 'Itinéraire',
      'organizer': 'Organisateur',
      'nearby_map': 'Carte des Événements',
      'digital_tickets': 'Mes Billets Numériques',
      'vendors_services': 'Prestataires & Services',
      'notifications': 'Notifications',
      'switch_language': 'Langue',
      'welcome_back': 'Bienvenue à nouveau',
      'welcome_new': 'Bienvenue sur EventPro !',
      'explore_now': 'Explorer Maintenant',
    },
  };

  static String tr(WidgetRef ref, String key) {
    final currentLang = ref.watch(languageProvider).code.toLowerCase();
    return _localizedValues[currentLang]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}
