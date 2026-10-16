import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/payment_provider.dart';
import '../utils/payment_route_args.dart';
import '../widgets/checkout_shell.dart';

/// M-Pesa STK Push checkout.
class MpesaCheckoutScreen extends ConsumerStatefulWidget {
  final String bookingType; // 'event' | 'service'
  final String itemId;
  final double amount;
  final String? itemTitle;
  final int quantity;

  const MpesaCheckoutScreen({
    super.key,
    required this.bookingType,
    required this.itemId,
    required this.amount,
    this.itemTitle,
    this.quantity = 1,
  });

  @override
  ConsumerState<MpesaCheckoutScreen> createState() =>
      _MpesaCheckoutScreenState();
}

class _MpesaCheckoutScreenState extends ConsumerState<MpesaCheckoutScreen> {
  static const _brandGradient = [Color(0xFF00A651), Color(0xFF007A3C)];

  String get _displayTitle => (widget.itemTitle != null &&
          widget.itemTitle!.trim().isNotEmpty)
      ? widget.itemTitle!.trim()
      : (widget.bookingType == 'event'
          ? 'Event Ticket #${widget.itemId}'
          : 'Service Booking #${widget.itemId}');

  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Pre-fill phone and email from user profile if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).valueOrNull?.user;
      if (user?.phone != null && _phoneCtrl.text.isEmpty) {
        _phoneCtrl.text = user!.phone!;
      }
      if (user?.email != null && user!.email.isNotEmpty && _emailCtrl.text.isEmpty) {
        _emailCtrl.text = user.email;
      }
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _initiatePayment() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    // Real M-Pesa PIN entry is a SYSTEM-level popup pushed by Safaricom's
    // network (STK Push) — it must NEVER be rendered inside this app. We call
    // the backend, which fires the Daraja STK Push to the user's handset; the
    // user then enters their PIN in Safaricom's own prompt. We navigate to the
    // status screen, which polls /payments/status/{id} until it completes.
    final user = ref.read(authStateProvider).valueOrNull?.user;
    final payment = await ref.read(paymentProvider.notifier).initiateStkPush(
          phone: phone,
          amount: widget.amount,
          bookingType: widget.bookingType,
          bookingId: int.tryParse(widget.itemId) ?? 0,
          email: email.isNotEmpty ? email : user?.email,
          fcmToken: user?.fcmToken ?? NotificationService.cachedToken,
          itemTitle: _displayTitle,
          quantity: widget.quantity,
        );

    if (!mounted) return;

    if (payment != null) {
      context.pushReplacement(paymentStatusLocation(
        transactionId: payment.transactionId,
        bookingType: widget.bookingType,
        itemId: widget.itemId,
        itemTitle: _displayTitle,
        quantity: widget.quantity,
      ));
    } else {
      _showError(ref.read(paymentProvider).error ??
          'We could not start the M-Pesa request. No payment has been taken.');
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
    final itemTitle = _displayTitle;

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
            'You\'ll receive an M-Pesa push notification on your phone. Enter your PIN to complete the payment. A confirmation receipt will be emailed to you.',
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
          const SizedBox(height: 16),
          const CheckoutFieldLabel('Email Address (for receipt confirmation)'),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: AppColors.textPrimary),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter your email to receive receipt';
              }
              if (!v.contains('@') || !v.contains('.')) {
                return 'Please enter a valid email address';
              }
              return null;
            },
            decoration: const InputDecoration(
              hintText: 'your-email@example.com',
              prefixIcon: Icon(Icons.email_outlined,
                  color: AppColors.primary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
