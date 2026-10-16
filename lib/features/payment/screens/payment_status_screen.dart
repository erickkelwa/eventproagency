import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_elevated_button.dart';
import '../../../core/constants/app_routes.dart';
import '../../events/providers/bookings_provider.dart';
import '../providers/payment_provider.dart';
import '../models/payment_model.dart';
import '../../../core/constants/api_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentStatusScreen extends ConsumerStatefulWidget {
  final String transactionId;

  /// Item context carried from checkout. Needed to issue the ticket to the
  /// account that actually paid (events use Firestore string ids, so the
  /// numeric `booking_id` returned by the API is not enough).
  final String? bookingType;
  final String? itemId;
  final String? itemTitle;
  final int quantity;

  const PaymentStatusScreen({
    super.key,
    required this.transactionId,
    this.bookingType,
    this.itemId,
    this.itemTitle,
    this.quantity = 1,
  });

  @override
  ConsumerState<PaymentStatusScreen> createState() =>
      _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends ConsumerState<PaymentStatusScreen> {
  Timer? _pollingTimer;
  int _pollCount = 0;
  static const int _maxPolls = 36; // 36 * 5s = 180s — matches the ~2-min lifetime of Safaricom's STK PIN prompt
  bool _isTimedOut = false;
  int _secondsLeft = 180;
  Timer? _countdownTimer;
  bool _ticketIssued = false;
  String? _ticketCode;

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
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _isTimedOut = false;
    _pollCount = 0;
    _secondsLeft = 180;
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();

    // Initial fetch
    ref.invalidate(paymentStatusProvider(widget.transactionId));

    // 1-second countdown timer for smooth UX feedback
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        timer.cancel();
      }
    });

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pollCount >= _maxPolls) {
        timer.cancel();
        _countdownTimer?.cancel();
        if (mounted) {
          setState(() {
            _isTimedOut = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.timer_off_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Payment request timed out. Please check your phone or retry.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 6),
            ),
          );
        }
        return;
      }

      final currentData =
          ref.read(paymentStatusProvider(widget.transactionId)).valueOrNull;

      if (currentData != null && !currentData.isPending) {
        timer.cancel(); // Stop polling if final state reached
        _countdownTimer?.cancel();
      } else {
        ref.invalidate(paymentStatusProvider(widget.transactionId));
      }
      _pollCount++;
    });
  }

  void _downloadReceipt() async {
    final rawPath =
        ApiConstants.downloadReceipt.replaceAll('{id}', widget.transactionId);
    final fullUrl =
        rawPath.startsWith('http') ? rawPath : '${ApiConstants.baseUrl}$rawPath';
    final uri = Uri.parse(fullUrl);
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri);
      }
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

  /// Attach the paid ticket to the SIGNED-IN account, exactly once.
  /// This is what fixes "I bought a ticket but someone else's data appeared":
  /// the ticket is written under the current Firebase uid, never inferred from
  /// a phone number or a shared admin id.
  Future<void> _issueTicketOnce(PaymentModel payment) async {
    if (_ticketIssued) return;
    _ticketIssued = true;

    final bookingType = widget.bookingType ?? payment.bookingType;
    final itemId = widget.itemId ?? '';

    try {
      final code = await ref.read(bookingsProvider.notifier).issueTicket(
            bookingType: bookingType,
            itemId: itemId.isEmpty ? '${payment.bookingId}' : itemId,
            transactionId: widget.transactionId,
            amount: payment.amount,
            quantity: widget.quantity,
            itemTitle: widget.itemTitle,
          );
      if (mounted && code != null) {
        setState(() => _ticketCode = code);
      }
    } catch (e) {
      // Ticket issuance failed (offline / rules). Keep the success screen but
      // tell the truth — the payment itself is already confirmed server-side.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Payment confirmed, but the ticket could not be added to My Tickets: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _goToMyTickets() {
    ref.read(bookingsProvider.notifier).refresh();
    context.go(AppRoutes.myBookings);
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
          if (_isTimedOut) {
            return _StatusView(
              title: 'Payment Timed Out',
              subtitle:
                  'We did not receive a response from M-Pesa in time. If you were charged, your booking will update automatically once confirmed.',
              iconColor: AppColors.error,
              iconData: Icons.timer_off_rounded,
              actionLabel: 'Retry Payment',
              onAction: _startPolling,
              secondaryActionLabel: 'Cancel & Return',
              onSecondaryAction: () => context.pop(),
            );
          } else if (payment.isPending) {
            return _StatusView(
              title: 'Processing Payment...',
              subtitle:
                  'Waiting for M-Pesa confirmation. Enter your PIN on your phone ($_secondsLeft s remaining).',
              iconColor: AppColors.primary,
              iconData: Icons.sync_rounded,
              isAnimating: true,
              actionLabel: 'Cancel STK Push',
              onAction: () {
                _pollingTimer?.cancel();
                _countdownTimer?.cancel();
                setState(() => _isTimedOut = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment request cancelled.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            );
          } else if (payment.isCompleted) {
            if (!_ticketIssued) {
              WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _issueTicketOnce(payment));
            }
            final title = (widget.itemTitle != null &&
                    widget.itemTitle!.isNotEmpty)
                ? widget.itemTitle!
                : null;
            return _SuccessView(
              payment: payment,
              itemTitle: title,
              ticketCode: _ticketCode,
              onDownload: _downloadReceipt,
              onHome: _goToMyTickets,
            );
          } else {
            return _StatusView(
              title: payment.status == 'cancelled'
                  ? 'Payment Cancelled'
                  : 'Payment Failed',
              subtitle: payment.status == 'cancelled'
                  ? 'The M-Pesa STK push request was cancelled on your phone.'
                  : 'The transaction could not be completed. Please check your balance or PIN.',
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
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  const _StatusView({
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.iconData,
    this.isAnimating = false,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
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
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAnimating ? AppColors.surface : AppColors.primary,
                  elevation: isAnimating ? 0 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                        color: isAnimating
                            ? AppColors.border
                            : Colors.transparent),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: TextStyle(
                    color: isAnimating
                        ? AppColors.error
                        : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
          if (secondaryActionLabel != null && onSecondaryAction != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: onSecondaryAction,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  secondaryActionLabel!,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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
  final String? itemTitle;
  final String? ticketCode;
  final VoidCallback onDownload;
  final VoidCallback onHome;

  const _SuccessView({
    required this.payment,
    required this.onDownload,
    required this.onHome,
    this.itemTitle,
    this.ticketCode,
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
          const SizedBox(height: 8),
          Text(
            itemTitle == null
                ? 'Congratulations — your booking is confirmed.'
                : 'Congratulations! Your ticket for\n$itemTitle is confirmed. 🎉',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
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
                _DetailRow(label: 'Amount Paid', value: '${payment.currency} ${payment.amount.toStringAsFixed(0)}'),
                Divider(color: AppColors.border, height: 24),
                _DetailRow(label: payment.receiptLabel, value: payment.displayReceipt),
                Divider(color: AppColors.border, height: 24),
                _DetailRow(label: 'Booking Ref', value: '#${payment.transactionId}'),
                if (ticketCode != null) ...[
                  Divider(color: AppColors.border, height: 24),
                  _DetailRow(label: 'Ticket Code', value: ticketCode!),
                ],
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
            label: const Text('Download Ticket / Receipt (Soft Copy)',
                style: TextStyle(color: AppColors.primary, fontSize: 12.5)),
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