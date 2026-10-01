import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_elevated_button.dart';
import '../../../core/constants/app_routes.dart';
import '../providers/payment_provider.dart';
import '../models/payment_model.dart';
import '../../../core/constants/api_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentStatusScreen extends ConsumerStatefulWidget {
  final String transactionId;

  const PaymentStatusScreen({super.key, required this.transactionId});

  @override
  ConsumerState<PaymentStatusScreen> createState() =>
      _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends ConsumerState<PaymentStatusScreen> {
  Timer? _pollingTimer;
  int _pollCount = 0;
  static const int _maxPolls = 12; // e.g. 12 * 5s = 60s timeout

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPolling();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Initial fetch
    ref.invalidate(paymentStatusProvider(widget.transactionId));

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pollCount >= _maxPolls) {
        timer.cancel();
        return;
      }
      
      final currentData = ref.read(paymentStatusProvider(widget.transactionId)).valueOrNull;
      
      if (currentData != null && !currentData.isPending) {
        timer.cancel(); // Stop polling if final state reached
      } else {
        ref.invalidate(paymentStatusProvider(widget.transactionId));
      }
      _pollCount++;
    });
  }

  void _downloadReceipt() async {
    final uri = Uri.parse(
        ApiConstants.downloadReceipt.replaceAll('{id}', widget.transactionId));
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not download receipt'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(paymentStatusProvider(widget.transactionId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: statusAsync.when(
          data: (data) => !data.isPending
              ? IconButton(
                  icon: Icon(Icons.close_rounded, color: AppColors.textPrimary),
                  onPressed: () => context.go(AppRoutes.home),
                )
              : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => IconButton(
            icon: Icon(Icons.close_rounded, color: AppColors.textPrimary),
            onPressed: () => context.go(AppRoutes.home),
          ),
        ),
      ),
      body: statusAsync.when(
        loading: () => _StatusView(
          title: 'Processing Payment...',
          subtitle: 'Please wait while we confirm with M-Pesa. Do not close this screen.',
          iconColor: AppColors.primary,
          iconData: Icons.sync_rounded,
          isAnimating: true,
        ),
        error: (err, _) => _StatusView(
          title: 'Connection Error',
          subtitle: err.toString(),
          iconColor: AppColors.error,
          iconData: Icons.error_outline_rounded,
          actionLabel: 'Retry',
          onAction: _startPolling,
        ),
        data: (payment) {
          if (payment.isPending) {
            return _StatusView(
              title: 'Processing Payment...',
              subtitle: 'Waiting for M-Pesa confirmation. This may take up to a minute.',
              iconColor: AppColors.primary,
              iconData: Icons.sync_rounded,
              isAnimating: true,
            );
          } else if (payment.isCompleted) {
            return _SuccessView(
              payment: payment,
              onDownload: _downloadReceipt,
              onHome: () => context.go(AppRoutes.home),
            );
          } else {
            return _StatusView(
              title: 'Payment Failed',
              subtitle: 'The transaction could not be completed or was cancelled.',
              iconColor: AppColors.error,
              iconData: Icons.cancel_rounded,
              actionLabel: 'Try Again',
              onAction: () => context.pop(),
            );
          }
        },
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color iconColor;
  final IconData iconData;
  final bool isAnimating;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StatusView({
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.iconData,
    this.isAnimating = false,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isAnimating)
            const SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 4,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 64),
            ),
          const SizedBox(height: 32),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final PaymentModel payment;
  final VoidCallback onDownload;
  final VoidCallback onHome;

  const _SuccessView({
    required this.payment,
    required this.onDownload,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
          ),
          const SizedBox(height: 32),
          Text(
            'Payment Successful!',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _DetailRow(label: 'Amount Paid', value: 'KES ${payment.amount.toStringAsFixed(0)}'),
                Divider(color: AppColors.border, height: 24),
                _DetailRow(label: 'M-Pesa Receipt', value: payment.mpesaReceiptNumber ?? 'N/A'),
                Divider(color: AppColors.border, height: 24),
                _DetailRow(label: 'Booking ID', value: '#${payment.bookingId}'),
              ],
            ),
          ),
          GradientElevatedButton(
            onPressed: onHome,
            child: const Text(
              'Go to My Tickets',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onDownload,
            icon: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
            label: const Text('Download Receipt', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
     ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        Text(value, style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}