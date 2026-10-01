import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../models/payment_model.dart';
import 'mpesa_checkout_screen.dart';
import 'airtel_checkout_screen.dart';
import 'paypal_checkout_screen.dart';
import 'equity_checkout_screen.dart';

/// Entry-point screen for all payment flows.
/// Displays branded payment method cards and navigates to the
/// appropriate sub-screen based on the user's selection.
class PaymentMethodScreen extends ConsumerStatefulWidget {
  final String bookingType; // 'event' | 'service'
  final String itemId;

  /// Final amount computed on the checkout screen. Falls back to a
  /// placeholder when this screen is opened directly (e.g. deep link).
  final double? amount;
  final String? itemTitle;

  const PaymentMethodScreen({
    super.key,
    required this.bookingType,
    required this.itemId,
    this.amount,
    this.itemTitle,
  });

  @override
  ConsumerState<PaymentMethodScreen> createState() =>
      _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends ConsumerState<PaymentMethodScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final List<AnimationController> _cardCtrls;

  double get _amount => widget.amount ?? 1500;

  String get _itemTitle =>
      widget.itemTitle ??
      (widget.bookingType == 'event'
          ? 'Event Ticket #${widget.itemId}'
          : 'Service Booking #${widget.itemId}');

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _cardCtrls = List.generate(4, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      Future.delayed(Duration(milliseconds: 100 + i * 80), ctrl.forward);
      return ctrl;
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    for (final c in _cardCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _selectMethod(PaymentMethod method) {
    Widget screen;
    switch (method) {
      case PaymentMethod.mpesa:
        screen = MpesaCheckoutScreen(
          bookingType: widget.bookingType,
          itemId: widget.itemId,
          amount: _amount,
        );
        break;
      case PaymentMethod.airtel:
        screen = AirtelCheckoutScreen(
          bookingType: widget.bookingType,
          itemId: widget.itemId,
          amount: _amount,
        );
        break;
      case PaymentMethod.paypal:
        screen = PaypalCheckoutScreen(
          bookingType: widget.bookingType,
          itemId: widget.itemId,
          amount: _amount,
        );
        break;
      case PaymentMethod.equity:
        screen = EquityCheckoutScreen(
          bookingType: widget.bookingType,
          itemId: widget.itemId,
          amount: _amount,
        );
        break;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, _) => screen,
        transitionsBuilder: (_, animation, _, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
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
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Choose Payment Method',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeCtrl,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Order Summary ────────────────────────────────
            _OrderSummaryCard(title: _itemTitle, amount: _amount),
            const SizedBox(height: 28),

            // ── Section Label ────────────────────────────────
            Text(
              'SELECT PAYMENT METHOD',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 14),

            // ── M-Pesa Card ──────────────────────────────────
            _PaymentMethodCard(
              animCtrl: _cardCtrls[0],
              methodName: 'M-Pesa',
              subtitle: 'Pay via Safaricom STK Push',
              icon: Icons.phone_android_rounded,
              color: const Color(0xFF00A651),
              gradientColors: [Color(0xFF00A651), Color(0xFF007A3C)],
              badge: 'Most Popular',
              onTap: () => _selectMethod(PaymentMethod.mpesa),
            ),
            const SizedBox(height: 12),

            // ── Airtel Money Card ────────────────────────────
            _PaymentMethodCard(
              animCtrl: _cardCtrls[1],
              methodName: 'Airtel Money',
              subtitle: 'Pay via Airtel Africa USSD Push',
              icon: Icons.sim_card_rounded,
              color: const Color(0xFFE40000),
              gradientColors: [Color(0xFFE40000), Color(0xFF9B0000)],
              onTap: () => _selectMethod(PaymentMethod.airtel),
            ),
            const SizedBox(height: 12),

            // ── Equity / EazzyPay Card ───────────────────────
            _PaymentMethodCard(
              animCtrl: _cardCtrls[2],
              methodName: 'Equity Bank',
              subtitle: 'EazzyPay or Debit / Credit Card',
              icon: Icons.credit_card_rounded,
              color: const Color(0xFF8B0000),
              gradientColors: [Color(0xFF8B0000), Color(0xFF5C0000)],
              onTap: () => _selectMethod(PaymentMethod.equity),
            ),
            const SizedBox(height: 12),

            // ── PayPal Card ──────────────────────────────────
            _PaymentMethodCard(
              animCtrl: _cardCtrls[3],
              methodName: 'PayPal',
              subtitle: 'Pay securely with your PayPal account',
              icon: Icons.language_rounded,
              color: const Color(0xFF003087),
              gradientColors: [Color(0xFF009CDE), Color(0xFF003087)],
              onTap: () => _selectMethod(PaymentMethod.paypal),
            ),

            const SizedBox(height: 28),

            // ── Security Note ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'All transactions are encrypted and secured by industry-standard protocols.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Order Summary Card ─────────────────────────────────────────
class _OrderSummaryCard extends StatelessWidget {
  final String title;
  final double amount;

  const _OrderSummaryCard({required this.title, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ShaderMask(
                shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                child: Text(
                  'KES ${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
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

// ── Payment Method Card ────────────────────────────────────────
class _PaymentMethodCard extends StatefulWidget {
  final AnimationController animCtrl;
  final String methodName;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Color> gradientColors;
  final String? badge;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.animCtrl,
    required this.methodName,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.gradientColors,
    required this.onTap,
    this.badge,
  });

  @override
  State<_PaymentMethodCard> createState() => _PaymentMethodCardState();
}

class _PaymentMethodCardState extends State<_PaymentMethodCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.3, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: widget.animCtrl,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(
        opacity: widget.animCtrl,
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _hovered = true),
          onTapUp: (_) => setState(() => _hovered = false),
          onTapCancel: () => setState(() => _hovered = false),
          child: AnimatedScale(
            scale: _hovered ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _hovered
                      ? widget.color.withValues(alpha: 0.5)
                      : AppColors.border,
                  width: _hovered ? 1.5 : 1,
                ),
                boxShadow: _hovered
                    ? [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
              ),
              child: Row(
                children: [
                  // Icon container with gradient
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.methodName,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (widget.badge != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: widget.gradientColors,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  widget.badge!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
