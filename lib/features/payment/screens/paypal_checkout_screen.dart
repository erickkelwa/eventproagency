import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/payment_provider.dart';
import '../widgets/checkout_shell.dart';

/// PayPal checkout — creates an order, opens the approval URL in a
/// browser/WebView, then captures the payment when the user returns.
class PaypalCheckoutScreen extends ConsumerStatefulWidget {
  final String bookingType; // 'event' | 'service'
  final String itemId;
  final double amount; // in KES

  const PaypalCheckoutScreen({
    super.key,
    required this.bookingType,
    required this.itemId,
    required this.amount,
  });

  @override
  ConsumerState<PaypalCheckoutScreen> createState() =>
      _PaypalCheckoutScreenState();
}

class _PaypalCheckoutScreenState extends ConsumerState<PaypalCheckoutScreen> {
  static const _brandGradient = [Color(0xFF009CDE), Color(0xFF003087)];

  /// Indicative KES → USD rate used for the estimate shown to the user.
  /// The backend applies the live rate when creating the order.
  static const double _kesPerUsd = 129.0;

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  // Step 2 state (set once the PayPal order exists)
  String? _orderId;
  String? _transactionId;
  double _usdAmount = 0;
  bool _capturing = false;

  bool get _awaitingApproval => _orderId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).valueOrNull?.user;
      if (user?.email != null && _emailCtrl.text.isEmpty) {
        _emailCtrl.text = user!.email;
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  double get _estimatedUsd => widget.amount / _kesPerUsd;

  Future<void> _createOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref.read(paymentProvider.notifier).initiatePaypalOrder(
          amount: _estimatedUsd,
          currency: 'USD',
          bookingType: widget.bookingType,
          bookingId: int.tryParse(widget.itemId) ?? 0,
        );

    if (!mounted || result == null) {
      _showError('Could not create the PayPal order. Please try again.');
      return;
    }

    setState(() {
      _orderId = result['order_id'];
      _transactionId = result['transaction_id'];
      _usdAmount = _estimatedUsd;
    });

    // Open the PayPal approval page
    final approvalUrl = result['approval_url'];
    if (approvalUrl != null && approvalUrl.isNotEmpty) {
      try {
        await launchUrl(Uri.parse(approvalUrl),
            mode: LaunchMode.platformDefault);
      } catch (_) {
        _showError('Could not open PayPal automatically. Link: $approvalUrl');
      }
    }
  }

  Future<void> _capturePayment() async {
    final orderId = _orderId;
    final transactionId = _transactionId;
    if (orderId == null || transactionId == null) return;

    setState(() => _capturing = true);

    final payment =
        await ref.read(paymentProvider.notifier).capturePaypalPayment(
              orderId: orderId,
              transactionId: transactionId,
              amount: _usdAmount,
              bookingType: widget.bookingType,
              bookingId: int.tryParse(widget.itemId) ?? 0,
            );

    if (!mounted) return;
    setState(() => _capturing = false);

    if (payment != null) {
      context.pushReplacement('/payment-status/${payment.transactionId}');
    } else {
      _showError('We could not confirm your PayPal payment yet.');
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
    final isLoading = paymentState.isLoading || _capturing;
    final itemTitle = widget.bookingType == 'event'
        ? 'Event Ticket #${widget.itemId}'
        : 'Service Booking #${widget.itemId}';

    return Form(
      key: _formKey,
      child: GatewayCheckoutScaffold(
        appBarTitle: 'Checkout',
        brandName: 'Pay with PayPal',
        brandTagline: 'Pay securely with your PayPal account',
        brandIcon: Icons.language_rounded,
        brandGradient: _brandGradient,
        itemTitle: itemTitle,
        amount: widget.amount,
        isLoading: isLoading,
        payLabel: _awaitingApproval
            ? 'I\'ve Completed Payment'
            : 'Continue to PayPal',
        onPay: _awaitingApproval ? _capturePayment : _createOrder,
        note: _awaitingApproval
            ? 'After approving the payment on PayPal, return here and tap the button above to confirm.'
            : 'You\'ll be redirected to PayPal to review and approve this payment in USD. PayPal applies its own exchange rate.',
        formFields: _awaitingApproval
            ? [
                _ApprovalPendingCard(
                  orderId: _orderId!,
                  usdAmount: _usdAmount,
                ),
              ]
            : [
                OrderSummaryCard(
                  itemTitle: 'USD estimate',
                  amount: _estimatedUsd,
                  currency: r'$',
                  extraRows: [
                    CheckoutRow(
                      label: 'Exchange rate (indicative)',
                      value: '1 USD ≈ KES ${_kesPerUsd.toStringAsFixed(0)}',
                      muted: true,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const CheckoutFieldLabel('PayPal Email'),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: AppColors.textPrimary),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(v.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.email_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                ),
              ],
      ),
    );
  }
}

// ── Awaiting Approval Card ─────────────────────────────────────
class _ApprovalPendingCard extends StatelessWidget {
  final String orderId;
  final double usdAmount;

  const _ApprovalPendingCard({required this.orderId, required this.usdAmount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(Color(0xFF009CDE)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Waiting for PayPal approval',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Approve ${formatMoney(usdAmount, currency: r'$')} in your browser to continue.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Order ID',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    orderId,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
