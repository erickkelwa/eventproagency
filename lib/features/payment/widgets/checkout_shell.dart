import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/widgets/gradient_button.dart';

/// Formats an amount with sensible decimals (0 for whole KES, 2 otherwise).
String formatMoney(double amount, {String currency = 'KES'}) {
  final decimals = amount % 1 == 0 ? 0 : 2;
  return '$currency ${amount.toStringAsFixed(decimals)}';
}

/// Shared premium shell for every gateway checkout screen
/// (M-Pesa, Airtel Money, Equity Bank, PayPal).
///
/// Renders: branded header card → order summary → gateway form fields →
/// info note → gradient pay button → optional extra sections.
class GatewayCheckoutScaffold extends StatelessWidget {
  final String appBarTitle;
  final String brandName;
  final String brandTagline;
  final IconData brandIcon;
  final List<Color> brandGradient;
  final String itemTitle;
  final double amount;
  final String currency;
  final String note;
  final List<Widget> formFields;
  final String payLabel;
  final bool isLoading;
  final VoidCallback? onPay;
  final List<Widget> extraSections;

  const GatewayCheckoutScaffold({
    super.key,
    required this.appBarTitle,
    required this.brandName,
    required this.brandTagline,
    required this.brandIcon,
    required this.brandGradient,
    required this.itemTitle,
    required this.amount,
    required this.formFields,
    required this.payLabel,
    required this.onPay,
    this.currency = 'KES',
    this.note = '',
    this.isLoading = false,
    this.extraSections = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          appBarTitle,
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _BrandHeader(
            brandName: brandName,
            brandTagline: brandTagline,
            brandIcon: brandIcon,
            brandGradient: brandGradient,
          ),
          const SizedBox(height: 24),
          OrderSummaryCard(
            itemTitle: itemTitle,
            amount: amount,
            currency: currency,
          ),
          const SizedBox(height: 24),
          ...formFields,
          if (note.isNotEmpty) ...[
            const SizedBox(height: 12),
            CheckoutNote(text: note, accent: brandGradient.first),
          ],
          const SizedBox(height: 32),
          GradientButton(
            onPressed: isLoading ? null : onPay,
            isLoading: isLoading,
            label: payLabel,
            gradientColors: brandGradient,
          ),
          ...extraSections,
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Branded Header ─────────────────────────────────────────────
class _BrandHeader extends StatelessWidget {
  final String brandName;
  final String brandTagline;
  final IconData brandIcon;
  final List<Color> brandGradient;

  const _BrandHeader({
    required this.brandName,
    required this.brandTagline,
    required this.brandIcon,
    required this.brandGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: brandGradient.last.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: brandGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(brandIcon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 14),
          Text(
            brandName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            brandTagline,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Order Summary ──────────────────────────────────────────────
class OrderSummaryCard extends StatelessWidget {
  final String itemTitle;
  final double amount;
  final String currency;
  final List<CheckoutRow> extraRows;
  final String? subtitle;

  const OrderSummaryCard({
    super.key,
    required this.itemTitle,
    required this.amount,
    this.currency = 'KES',
    this.extraRows = const [],
    this.subtitle,
  });

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ORDER SUMMARY',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          CheckoutRow(
            label: itemTitle,
            value: formatMoney(amount, currency: currency),
            subtitle: subtitle,
          ),
          ...extraRows,
          Divider(color: AppColors.border, height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              ShaderMask(
                shaderCallback: (b) =>
                    AppColors.primaryGradient.createShader(b),
                child: Text(
                  formatMoney(amount, currency: currency),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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

/// A single label → value line inside the order summary.
class CheckoutRow extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final bool muted;

  const CheckoutRow({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: muted ? AppColors.textMuted : AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              color: muted ? AppColors.textMuted : AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Note ──────────────────────────────────────────────────
class CheckoutNote extends StatelessWidget {
  final String text;
  final Color accent;
  final IconData icon;

  const CheckoutNote({
    super.key,
    required this.text,
    this.accent = AppColors.primary,
    this.icon = Icons.info_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Field Label ────────────────────────────────────────────────
class CheckoutFieldLabel extends StatelessWidget {
  final String text;

  const CheckoutFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Validates any Kenyan mobile number (07XX / 01XX / 2547XX / +254...).
String? validateKenyaPhone(String? value, {String network = 'mobile'}) {
  if (value == null || value.trim().isEmpty) {
    return 'Phone number is required';
  }
  final cleaned = value.replaceAll(RegExp(r'[\s\-\+]'), '');
  if (!RegExp(r'^(254|0)?[17]\d{8}$').hasMatch(cleaned)) {
    return 'Enter a valid $network number (e.g. 0712345678)';
  }
  return null;
}

/// Normalizes a Kenyan number to the 254XXXXXXXXX format.
String normalizeKenyaPhone(String phone) {
  final cleaned = phone.replaceAll(RegExp(r'[\s\-\+]'), '');
  if (cleaned.startsWith('0')) return '254${cleaned.substring(1)}';
  if (!cleaned.startsWith('254')) return '254$cleaned';
  return cleaned;
}
