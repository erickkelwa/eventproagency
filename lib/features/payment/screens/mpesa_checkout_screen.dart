import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/payment_provider.dart';
import '../widgets/checkout_shell.dart';

/// M-Pesa STK Push checkout.
class MpesaCheckoutScreen extends ConsumerStatefulWidget {
  final String bookingType; // 'event' | 'service'
  final String itemId;
  final double amount;

  const MpesaCheckoutScreen({
    super.key,
    required this.bookingType,
    required this.itemId,
    required this.amount,
  });

  @override
  ConsumerState<MpesaCheckoutScreen> createState() =>
      _MpesaCheckoutScreenState();
}

class _MpesaCheckoutScreenState extends ConsumerState<MpesaCheckoutScreen> {
  static const _brandGradient = [Color(0xFF00A651), Color(0xFF007A3C)];

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
    final payment = await ref.read(paymentProvider.notifier).initiateStkPush(
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
        brandName: 'Pay with M-Pesa',
        brandTagline: 'Secure payment via Safaricom',
        brandIcon: Icons.phone_android_rounded,
        brandGradient: _brandGradient,
        itemTitle: itemTitle,
        amount: widget.amount,
        payLabel: 'Pay ${formatMoney(widget.amount)} Now',
        isLoading: paymentState.isLoading,
        onPay: _initiatePayment,
        note:
            'You\'ll receive an M-Pesa push notification on your phone. Enter your PIN to complete the payment.',
        formFields: [
          const CheckoutFieldLabel('M-Pesa Phone Number'),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: AppColors.textPrimary),
            validator: (v) => validateKenyaPhone(v, network: 'Safaricom'),
            decoration: const InputDecoration(
              hintText: '0712 345 678',
              prefixIcon: Icon(Icons.phone_rounded,
                  color: AppColors.primary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
