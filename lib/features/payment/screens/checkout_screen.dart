import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/widgets/gradient_button.dart';
import '../../events/providers/events_provider.dart';
import '../../services/providers/services_provider.dart';
import '../widgets/checkout_shell.dart';
import 'payment_method_screen.dart';

/// Order review screen.
///
/// Reached from the event / service detail screens via
/// `/checkout/:bookingType/:id`. Pulls the real item, lets the user
/// pick a ticket quantity, shows the price breakdown and then
/// hands off to [PaymentMethodScreen] with the final amount.
class CheckoutScreen extends ConsumerStatefulWidget {
  final String bookingType; // 'event' | 'service'
  final String itemId;

  const CheckoutScreen({
    super.key,
    required this.bookingType,
    required this.itemId,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  static const double _feeRate = 0.05;
  static const int _maxTicketsPerOrder = 10;

  int _quantity = 1;

  bool get _isEvent => widget.bookingType == 'event';

  double get _subtotal => _unitPrice * _quantity;
  double get _fee => _subtotal * _feeRate;
  double get _total => _subtotal + _fee;

  double _unitPrice = 0;

  void _goToPaymentMethod(String itemTitle) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => PaymentMethodScreen(
          bookingType: widget.bookingType,
          itemId: widget.itemId,
          amount: _total,
          itemTitle: itemTitle,
        ),
        transitionsBuilder: (_, animation, _, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Checkout',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: _isEvent ? _buildEventCheckout() : _buildServiceCheckout(),
    );
  }

  // ── Event Flow ─────────────────────────────────────────────
  Widget _buildEventCheckout() {
    final async = ref.watch(singleEventProvider(widget.itemId));

    return async.when(
      loading: () => const _CheckoutSkeleton(),
      error: (e, _) => _ErrorView(message: '$e'),
      data: (event) {
        _unitPrice = event.price;
        final maxQty = event.availableSlots < _maxTicketsPerOrder
            ? event.availableSlots
            : _maxTicketsPerOrder;
        if (_quantity > maxQty && maxQty > 0) _quantity = maxQty;

        if (event.isSoldOut) {
          return _ErrorView(
            message: 'Sorry, "${event.title}" is sold out.',
            icon: Icons.event_busy_rounded,
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _ItemHeroCard(
              title: event.title,
              subtitle:
                  '${DateFormat('EEE, MMM d · h:mm a').format(event.date)}\n${event.venue}',
              imageUrl: event.imageUrl,
              fallbackIcon: Icons.celebration_rounded,
            ),
            const SizedBox(height: 20),
            _QuantityCard(
              quantity: _quantity,
              maxQuantity: maxQty,
              unitPrice: event.price,
              onDecrement: () => setState(() => _quantity--),
              onIncrement: () => setState(() => _quantity++),
            ),
            const SizedBox(height: 20),
            OrderSummaryCard(
              itemTitle: '${event.title} × $_quantity',
              subtitle: formatMoney(event.price),
              amount: _total,
              extraRows: [
                CheckoutRow(
                  label: 'Booking fee (5%)',
                  value: formatMoney(_fee),
                  muted: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
            CheckoutNote(
              text:
                  'Your ticket will be available in "My Tickets" immediately after payment.',
              icon: Icons.confirmation_number_rounded,
            ),
            const SizedBox(height: 32),
            GradientButton(
              onPressed: () =>
                  _goToPaymentMethod('${event.title} × $_quantity'),
              label: 'Continue · ${formatMoney(_total)}',
              icon: Icons.lock_rounded,
            ),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  // ── Service Flow ───────────────────────────────────────────
  Widget _buildServiceCheckout() {
    final async = ref.watch(singleServiceProvider(widget.itemId));

    return async.when(
      loading: () => const _CheckoutSkeleton(),
      error: (e, _) => _ErrorView(message: '$e'),
      data: (service) {
        _unitPrice = service.basePrice;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _ItemHeroCard(
              title: service.name,
              subtitle: service.category,
              imageUrl: service.imageUrl,
              fallbackIcon: Icons.handshake_rounded,
            ),
            const SizedBox(height: 20),
            OrderSummaryCard(
              itemTitle: service.name,
              subtitle: service.priceRange.isEmpty
                  ? null
                  : 'Range: ${service.priceRange}',
              amount: _total,
              extraRows: [
                CheckoutRow(
                  label: 'Booking fee (5%)',
                  value: formatMoney(_fee),
                  muted: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
            CheckoutNote(
              text:
                  'The provider will confirm your booking details after payment. Final pricing may be adjusted by the provider.',
              icon: Icons.info_outline_rounded,
            ),
            const SizedBox(height: 32),
            GradientButton(
              onPressed: () => _goToPaymentMethod(service.name),
              label: 'Continue · ${formatMoney(_total)}',
              icon: Icons.lock_rounded,
            ),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }
}

// ── Item Hero Card ─────────────────────────────────────────────
class _ItemHeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final IconData fallbackIcon;

  const _ItemHeroCard({
    required this.title,
    required this.subtitle,
    required this.fallbackIcon,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 72,
              height: 72,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _fallbackTile(),
                      loadingBuilder: (context, child, progress) =>
                          progress == null ? child : _fallbackTile(),
                    )
                  : _fallbackTile(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackTile() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.25),
            AppColors.primaryDark.withValues(alpha: 0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(fallbackIcon, color: AppColors.primary, size: 30),
    );
  }
}

// ── Quantity Selector ──────────────────────────────────────────
class _QuantityCard extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final double unitPrice;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityCard({
    required this.quantity,
    required this.maxQuantity,
    required this.unitPrice,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TICKETS',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatMoney(unitPrice)} each · max $maxQuantity',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          _QtyButton(
            icon: Icons.remove_rounded,
            onTap: quantity > 1 ? onDecrement : null,
          ),
          SizedBox(
            width: 44,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _QtyButton(
            icon: Icons.add_rounded,
            onTap: quantity < maxQuantity ? onIncrement : null,
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.14)
              : AppColors.surface,
          border: Border.all(
            color: enabled
                ? AppColors.primary.withValues(alpha: 0.45)
                : AppColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.primary : AppColors.textMuted,
        ),
      ),
    );
  }
}

// ── Loading Skeleton ───────────────────────────────────────────
class _CheckoutSkeleton extends StatelessWidget {
  const _CheckoutSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget block(double height, {double width = double.infinity, radius = 16}) {
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: AppColors.card,
        highlightColor: AppColors.cardHover,
        child: Column(
          children: [
            block(104, radius: 20),
            const SizedBox(height: 20),
            block(76, radius: 20),
            const SizedBox(height: 20),
            block(160, radius: 20),
            const SizedBox(height: 32),
            block(60, radius: 50),
          ],
        ),
      ),
    );
  }
}

// ── Error / Sold-out View ──────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final IconData icon;

  const _ErrorView({required this.message, this.icon = Icons.error_outline_rounded});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, color: AppColors.error, size: 38),
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
