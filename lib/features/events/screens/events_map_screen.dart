import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../models/event_model.dart';
import '../../../core/widgets/pro_badges.dart';

/// Interactive Map View showing geo-located events across the city/region.
class EventsMapScreen extends StatefulWidget {
  final List<EventModel> events;

  const EventsMapScreen({super.key, required this.events});

  @override
  State<EventsMapScreen> createState() => _EventsMapScreenState();
}

class _EventsMapScreenState extends State<EventsMapScreen> {
  EventModel? _selectedEvent;

  static const LatLng _defaultCenter = LatLng(-1.286389, 36.817223); // Nairobi Center

  @override
  Widget build(BuildContext context) {
    final validEvents = widget.events
        .where((e) => e.latitude != null && e.longitude != null)
        .toList();

    final markers = validEvents.map((event) {
      return Marker(
        markerId: MarkerId(event.id),
        position: LatLng(event.latitude!, event.longitude!),
        infoWindow: InfoWindow(title: event.title, snippet: event.venue),
        onTap: () {
          setState(() {
            _selectedEvent = event;
          });
        },
      );
    }).toSet();

    final initialTarget = validEvents.isNotEmpty
        ? LatLng(validEvents.first.latitude!, validEvents.first.longitude!)
        : _defaultCenter;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Nearby Events Map',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(target: initialTarget, zoom: 12.5),
            markers: markers,
            onTap: (_) {
              if (_selectedEvent != null) {
                setState(() => _selectedEvent = null);
              }
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Top floating badge
          Positioned(
            top: 16,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${validEvents.length} events with venue coordinates',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Selected Event Preview Sheet
          if (_selectedEvent != null)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: () => context.push('/events/${_selectedEvent!.id}'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: EventCategoryMeta.color(_selectedEvent!.category)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.event_seat_rounded,
                          color: EventCategoryMeta.color(_selectedEvent!.category),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedEvent!.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedEvent!.venue,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedEvent!.formattedPrice,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_forward_rounded,
                            size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
