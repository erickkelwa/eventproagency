import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../../features/events/models/booking_model.dart';
import 'pro_badges.dart';

/// ── Pro Booking Card ───────────────────────────────────────────────────────
/// Real ticket design for user bookings:
///  • hero image with glass category chip + solid status chip
///  • perforated divider (dashed line + side notches) like a physical ticket
///  • details section (date, venue, quantity)
///  • ticket stub with code, generated barcode, copy-to-clipboard and amount
///  • cancelled tickets render desaturated
class ProBookingCard extends StatelessWidget {
  final BookingModel booking;

  const ProBookingCard({super.key, required this.booking});

  static const double _heroHeight = 140;
  static const double _dividerBand = 22;
  static const double _notchRadius = 9;

  @override
  Widget build(BuildContext context) {
    final b = booking;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: b.isConfirmed
              ? AppColors.primary.withValues(alpha: 0.30)
              : AppColors.border.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          if (b.isConfirmed)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero image ──────────────────────────────────────
              SizedBox(
                height: _heroHeight,
                width: double.infinity,
                child: _HeroSection(booking: b),
              ),

              // ── Perforated divider ──────────────────────────────
              SizedBox(
                height: _dividerBand,
                width: double.infinity,
                child: CustomPaint(
                  painter: _DashedLinePainter(
                    color: AppColors.border.withValues(alpha: 0.9),
                  ),
                ),
              ),

              // ── Details ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(
                      icon: Icons.calendar_today_rounded,
                      text:
                          '${DateFormat('EEE, MMM d · h:mm a').format(b.eventDate)}'
                          '${b.quantity > 1 ? '  ·  ${b.quantity} tickets' : ''}',
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(
                      icon: Icons.location_on_rounded,
                      text: b.venue,
                    ),
                  ],
                ),
              ),

              // ── Ticket stub ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _TicketStub(booking: b),
              ),
            ],
          ),

          // ── Perforation notches ──────────────────────────────────
          Positioned(
            left: -_notchRadius,
            top: _heroHeight + _dividerBand / 2 - _notchRadius,
            child: _Notch(radius: _notchRadius),
          ),
          Positioned(
            right: -_notchRadius,
            top: _heroHeight + _dividerBand / 2 - _notchRadius,
            child: _Notch(radius: _notchRadius),
          ),
        ],
      ),
    );
  }
}

/// ── Hero Section ───────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final BookingModel booking;
  const _HeroSection({required this.booking});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    Widget image;

    if (b.imageUrl != null && b.imageUrl!.isNotEmpty) {
      image = CachedNetworkImage(
        imageUrl: b.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _gradientPlaceholder(),
        errorWidget: (context, url, error) => _assetFallback(),
      );
    } else {
      image = _assetFallback();
    }

    if (b.isCancelled) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Colors.grey,
          BlendMode.saturation,
        ),
        child: image,
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          image,

          // Legibility gradient
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x55000000), Colors.transparent, Color(0xD9000000)],
                stops: [0.0, 0.35, 1.0],
              ),
            ),
          ),

          // Category chip (glass)
          Positioned(
            top: 12,
            left: 12,
            child: ProBadge(
              label: b.category,
              color: EventCategoryMeta.color(b.category),
              glass: true,
            ),
          ),

          // Status chip (solid for readability over imagery)
          Positioned(
            top: 12,
            right: 12,
            child: _SolidStatusChip(status: b.status),
          ),

          // Title
          Positioned(
            bottom: 12,
            left: 14,
            right: 14,
            child: Text(
              b.eventTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _assetFallback() {
    return Image.asset(
      EventCategoryMeta.assetImage(booking.category),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _gradientPlaceholder(),
    );
  }

  Widget _gradientPlaceholder() {
    return Container(
      decoration: BoxDecoration(gradient: AppColors.primaryGradient),
      child: const Center(
        child: Icon(Icons.event_rounded, size: 48, color: Colors.white24),
      ),
    );
  }
}

/// ── Solid Status Chip ──────────────────────────────────────────────────────
/// Opaque status pill that stays readable over any image.
class _SolidStatusChip extends StatelessWidget {
  final String status;
  const _SolidStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status.toLowerCase()) {
      'confirmed' => ('Confirmed', AppColors.primary, Icons.check_circle_rounded),
      'attended' => ('Attended', AppColors.success, Icons.done_all_rounded),
      'cancelled' => ('Cancelled', AppColors.error, Icons.cancel_rounded),
      _ => ('Pending', AppColors.warning, Icons.pending_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// ── Detail Row ─────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 13, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// ── Ticket Stub ────────────────────────────────────────────────────────────
/// Recessed strip holding the ticket code, barcode, copy action and amount.
class _TicketStub extends StatelessWidget {
  final BookingModel booking;
  const _TicketStub({required this.booking});

  @override
  Widget build(BuildContext context) {
    final b = booking;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: b.isConfirmed
              ? AppColors.primary.withValues(alpha: 0.30)
              : AppColors.border.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: code + copy
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TICKET CODE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      b.ticketCode,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Clipboard.setData(ClipboardData(text: b.ticketCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Ticket code copied to clipboard'),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.30),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.copy_rounded,
                      color: Colors.black, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: barcode + amount
          Row(
            children: [
              _Barcode(
                code: b.ticketCode,
                color: AppColors.textPrimary.withValues(alpha: 0.55),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient:
                      b.isCancelled ? null : AppColors.primaryGradient,
                  color: b.isCancelled ? AppColors.card : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'KES ${b.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: b.isCancelled ? AppColors.textMuted : Colors.black,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ── Barcode ────────────────────────────────────────────────────────────────
/// Decorative barcode generated deterministically from the ticket code.
class _Barcode extends StatelessWidget {
  final String code;
  final Color color;

  const _Barcode({required this.code, required this.color});

  @override
  Widget build(BuildContext context) {
    // Use a stable slice of the code so every render is identical.
    final source = (code.padRight(10, '0')).substring(0, 10);
    final bars = <Widget>[];
    for (var i = 0; i < source.length; i++) {
      final width = 1.5 + (source.codeUnitAt(i) % 3); // 1.5 – 3.5 px
      bars.add(Container(width: width, height: 22, color: color));
      bars.add(const SizedBox(width: 2));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: bars);
  }
}

/// ── Notch ──────────────────────────────────────────────────────────────────
/// Circle punched into the card edge to simulate a perforation cut-out.
class _Notch extends StatelessWidget {
  final double radius;
  const _Notch({required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.background,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.6),
          width: 0.6,
        ),
      ),
    );
  }
}

/// ── Dashed Line Painter ────────────────────────────────────────────────────
class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    const dashWidth = 6.0;
    const dashGap = 6.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(x + dashWidth, size.height / 2),
        paint,
      );
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      color != oldDelegate.color;
}
