import 'package:flutter/material.dart';
import '../../../core/widgets/pro_event_card.dart';
import '../models/event_model.dart';

/// Thin compatibility wrapper — the app-wide event card is now [ProEventCard]
/// from the core pro widget system. Existing call sites keep working.
class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const EventCard({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) => ProEventCard(event: event, onTap: onTap);
}
