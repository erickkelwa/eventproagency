import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/payment_provider.dart';
import '../widgets/checkout_shell.dart';

/// Airtel Money push checkout.
class AirtelCheckoutScreen extends ConsumerStatefulWidget {
  final String bookingType; // 'event' | 'service'
  final String itemId;
  final double amount;

  const AirtelCheckoutScreen({
    super.key,
    required this.bookingType,
    required this.itemId,
    required this.amount,
  });

  @override
  ConsumerState<AirtelCheckoutScreen> createState() =>
      _AirtelCheckoutScreenState();
}

class _AirtelCheckoutScreenState extends ConsumerState<AirtelCheckoutScreen> {
  static const _brandGradient = [Color(0xFFE40000), Color(0xFF9B0000)];

  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Pre-fill phone from user profile if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).valueOrNull?.user;
      if (user?.phone != null && _phoneCtrl.text.isEmpty) {
        _phoneCtrl.text = user!.phone!;
      }
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _initiatePayment() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authStateProvider).valueOrNull?.user;
    final payment = await ref.read(paymentProvider.notifier).initiateAirtelPush(
          phone: _phoneCtrl.text.trim(),
          amount: widget.amount,
          bookingType: widget.bookingType,
          bookingId: int.tryParse(widget.itemId) ?? 0,
          email: user?.email,
          fcmToken: user?.fcmToken ?? NotificationService.cachedToken,
        );

    if (!mounted) return;

    if (payment != null) {
      context.pushReplacement('/payment-status/${payment.transactionId}');
    } else {
      _showError(ref.read(paymentProvider).error ?? 'Payment initiation failed');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);
    final itemTitle = widget.bookingType == 'event'
        ? 'Event Ticket #${widget.itemId}'
        : 'Service Booking #${widget.itemId}';

    return Form(
      key: _formKey,
      child: GatewayCheckoutScaffold(
        appBarTitle: 'Checkout',
        brandName: 'Pay with Airtel Money',
        brandTagline: 'Secure payment via Airtel Africa',
        brandIcon: Icons.sim_card_rounded,
        brandGradient: _brandGradient,
        itemTitle: itemTitle,
        amount: widget.amount,
        payLabel: 'Pay ${formatMoney(widget.amount)} Now',
        isLoading: paymentState.isLoading,
        onPay: _initiatePayment,
        note:
            'You\'ll receive a payment prompt on your Airtel line. Enter your PIN to authorize the transaction.',
        formFields: [
          const CheckoutFieldLabel('Airtel Money Phone Number'),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: AppColors.textPrimary),
            validator: (v) => validateKenyaPhone(v, network: 'Airtel'),
            decoration: const InputDecoration(
              hintText: '0733 123 456',
              prefixIcon: Icon(Icons.phone_rounded,
                  color: AppColors.primary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
