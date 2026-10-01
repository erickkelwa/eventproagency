import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/payment_provider.dart';
import '../widgets/checkout_shell.dart';

/// Equity Bank checkout — supports EazzyPay (phone push) and card payments.
class EquityCheckoutScreen extends ConsumerStatefulWidget {
  final String bookingType; // 'event' | 'service'
  final String itemId;
  final double amount;

  const EquityCheckoutScreen({
    super.key,
    required this.bookingType,
    required this.itemId,
    required this.amount,
  });

  @override
  ConsumerState<EquityCheckoutScreen> createState() =>
      _EquityCheckoutScreenState();
}

class _EquityCheckoutScreenState extends ConsumerState<EquityCheckoutScreen> {
  static const _brandGradient = [Color(0xFF8B0000), Color(0xFF5C0000)];

  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  /// 'eazzypay' | 'card'
  String _subtype = 'eazzypay';

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
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  Future<void> _initiatePayment() async {
    if (!_formKey.currentState!.validate()) return;

    final payment = await ref.read(paymentProvider.notifier).initiateEquityPayment(
          amount: widget.amount,
          bookingType: widget.bookingType,
          bookingId: int.tryParse(widget.itemId) ?? 0,
          paymentSubtype: _subtype,
          phone: _subtype == 'eazzypay' ? _phoneCtrl.text.trim() : null,
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
        brandName: 'Pay with Equity Bank',
        brandTagline: 'EazzyPay or Debit / Credit Card',
        brandIcon: Icons.credit_card_rounded,
        brandGradient: _brandGradient,
        itemTitle: itemTitle,
        amount: widget.amount,
        payLabel: 'Pay ${formatMoney(widget.amount)} Now',
        isLoading: paymentState.isLoading,
        onPay: _initiatePayment,
        note: _subtype == 'eazzypay'
            ? 'You\'ll receive an EazzyPay prompt on your phone. Approve it to complete the payment.'
            : 'Card details are encrypted end-to-end and tokenized before reaching our servers.',
        formFields: [
          _SubtypeToggle(
            selected: _subtype,
            onSelect: (value) => setState(() => _subtype = value),
          ),
          const SizedBox(height: 20),
          if (_subtype == 'eazzypay') ..._eazzyPayFields() else ..._cardFields(),
        ],
      ),
    );
  }

  List<Widget> _eazzyPayFields() {
    return [
      const CheckoutFieldLabel('Equity / EazzyPay Phone Number'),
      TextFormField(
        controller: _phoneCtrl,
        keyboardType: TextInputType.phone,
        style: TextStyle(color: AppColors.textPrimary),
        validator: (v) => validateKenyaPhone(v, network: 'Equity'),
        decoration: const InputDecoration(
          hintText: '0763 123 456',
          prefixIcon:
              Icon(Icons.phone_rounded, color: AppColors.primary, size: 20),
        ),
      ),
    ];
  }

  List<Widget> _cardFields() {
    return [
      const CheckoutFieldLabel('Card Number'),
      TextFormField(
        controller: _cardNumberCtrl,
        keyboardType: TextInputType.number,
        style: TextStyle(color: AppColors.textPrimary),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(16),
          _CardNumberFormatter(),
        ],
        validator: (v) {
          final digits = (v ?? '').replaceAll(' ', '');
          if (digits.length != 16) return 'Enter a valid 16-digit card number';
          return null;
        },
        decoration: const InputDecoration(
          hintText: '4111 1111 1111 1111',
          prefixIcon: Icon(Icons.credit_score_rounded,
              color: AppColors.primary, size: 20),
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CheckoutFieldLabel('Expiry'),
                TextFormField(
                  controller: _expiryCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: AppColors.textPrimary),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    _ExpiryFormatter(),
                  ],
                  validator: (v) {
                    final raw = (v ?? '').replaceAll('/', '');
                    if (raw.length != 4) return 'MM/YY';
                    final month = int.tryParse(raw.substring(0, 2)) ?? 0;
                    if (month < 1 || month > 12) return 'Invalid month';
                    return null;
                  },
                  decoration: const InputDecoration(hintText: 'MM/YY'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CheckoutFieldLabel('CVV'),
                TextFormField(
                  controller: _cvvCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  style: TextStyle(color: AppColors.textPrimary),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  validator: (v) =>
                      (v == null || v.length != 3) ? '3 digits' : null,
                  decoration: const InputDecoration(hintText: '•••'),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }
}

// ── Subtype Toggle ─────────────────────────────────────────────
class _SubtypeToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _SubtypeToggle({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _TogglePill(
            label: 'EazzyPay',
            icon: Icons.phone_android_rounded,
            active: selected == 'eazzypay',
            onTap: () => onSelect('eazzypay'),
          ),
          _TogglePill(
            label: 'Card',
            icon: Icons.credit_card_rounded,
            active: selected == 'card',
            onTap: () => onSelect('card'),
          ),
        ],
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _TogglePill({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: active ? AppColors.primaryGradient : null,
            color: active ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? Colors.white : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : AppColors.textMuted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Input Formatters ───────────────────────────────────────────
/// Groups card digits: 4111 1111 1111 1111
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formats expiry as MM/YY while typing.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('/', '');
    var formatted = digits;
    if (digits.length > 2) {
      formatted = '${digits.substring(0, 2)}/${digits.substring(2)}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
