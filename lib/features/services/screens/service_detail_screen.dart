import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../models/service_model.dart';
import '../providers/services_provider.dart';

class ServiceDetailScreen extends ConsumerStatefulWidget {
  final String serviceId;
  const ServiceDetailScreen({super.key, required this.serviceId});

  @override
  ConsumerState<ServiceDetailScreen> createState() =>
      _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends ConsumerState<ServiceDetailScreen> {
  final _dateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _dateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.card,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null && mounted) {
      setState(() {
        _selectedDate = date;
        _dateCtrl.text = '${date.day}/${date.month}/${date.year}';
      });
    }
  }

  Future<void> _bookService(ServiceModel service) async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an event date'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final booking = await ref.read(serviceBookingProvider.notifier).book(
          serviceId: service.id,
          eventDate: _selectedDate!.toIso8601String(),
          notes: _notesCtrl.text.trim(),
        );

    if (!mounted) return;

    if (booking != null) {
      // Navigate to checkout with the booking details
      context.push(
        '/checkout/service/${service.id}',
      );
    } else {
      final error = ref.read(serviceBookingProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Booking failed. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceAsync = ref.watch(singleServiceProvider(widget.serviceId));

    return serviceAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(err.toString(),
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
      data: (service) => _ServiceDetailBody(
        service: service,
        dateCtrl: _dateCtrl,
        notesCtrl: _notesCtrl,
        onPickDate: _pickDate,
        onBook: () => _bookService(service),
      ),
    );
  }
}

class _ServiceDetailBody extends ConsumerWidget {
  final ServiceModel service;
  final TextEditingController dateCtrl;
  final TextEditingController notesCtrl;
  final VoidCallback onPickDate;
  final VoidCallback onBook;

  const _ServiceDetailBody({
    required this.service,
    required this.dateCtrl,
    required this.notesCtrl,
    required this.onPickDate,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(serviceBookingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Category Color Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.8),
                          AppColors.secondary.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.room_service_rounded,
                      color: Colors.white.withValues(alpha: 0.2),
                      size: 120,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, AppColors.background],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      service.category.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Name
                  Text(
                    service.name,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Rating & Reviews
                  if (service.rating != null)
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < (service.rating ?? 0).floor()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: const Color(0xFFFFD700),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${service.rating!.toStringAsFixed(1)} (${service.reviewCount} reviews)',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Price
                  Row(
                    children: [
                      Text('From  ',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 14)),
                      ShaderMask(
                        shaderCallback: (b) =>
                            AppColors.primaryGradient.createShader(b),
                        child: Text(
                          service.priceRange,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  Text(
                    'About this Service',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service.description,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Contact options
                  Text(
                    'Contact Vendor',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ContactButton(
                          icon: Icons.phone_rounded,
                          label: 'Call',
                          color: AppColors.success,
                          onTap: () => launchUrl(
                            Uri.parse('tel:0728664792'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ContactButton(
                          icon: Icons.chat_rounded,
                          label: 'WhatsApp',
                          color: const Color(0xFF25D366),
                          onTap: () => launchUrl(
                            Uri.parse('https://wa.me/254728664792'),
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Book Form
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request Booking',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Event Date
                        GestureDetector(
                          onTap: onPickDate,
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: dateCtrl,
                              style: TextStyle(
                                  color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Select event date',
                                hintStyle: TextStyle(
                                    color: AppColors.textMuted),
                                prefixIcon: const Icon(
                                    Icons.calendar_today_rounded,
                                    color: AppColors.primary,
                                    size: 20),
                                filled: true,
                                fillColor: AppColors.inputFill,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                      color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                      color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                      color: AppColors.primary,
                                      width: 1.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Notes
                        TextFormField(
                          controller: notesCtrl,
                          maxLines: 3,
                          style: TextStyle(
                              color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText:
                                'Add any special requirements or notes...',
                            hintStyle:
                                TextStyle(color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.inputFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Book Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: service.isAvailable
                                  ? AppColors.primaryGradient
                                  : null,
                              color: service.isAvailable
                                  ? null
                                  : AppColors.border,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: service.isAvailable
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ElevatedButton(
                              onPressed: service.isAvailable &&
                                      !bookingState.isLoading
                                  ? onBook
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: bookingState.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      service.isAvailable
                                          ? 'Proceed to Payment'
                                          : 'Currently Unavailable',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contact Button ─────────────────────────────────────────
class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}