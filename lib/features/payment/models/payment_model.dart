import 'package:equatable/equatable.dart';

// ── Payment Method Enum ────────────────────────────────────────
enum PaymentMethod {
  mpesa,
  airtel,
  paypal,
  equity;

  String get label {
    switch (this) {
      case PaymentMethod.mpesa:   return 'M-Pesa';
      case PaymentMethod.airtel:  return 'Airtel Money';
      case PaymentMethod.paypal:  return 'PayPal';
      case PaymentMethod.equity:  return 'Equity Bank';
    }
  }

  String get receiptLabel {
    switch (this) {
      case PaymentMethod.mpesa:   return 'M-Pesa Receipt';
      case PaymentMethod.airtel:  return 'Airtel Transaction ID';
      case PaymentMethod.paypal:  return 'PayPal Order ID';
      case PaymentMethod.equity:  return 'Equity Reference';
    }
  }

  String get key {
    switch (this) {
      case PaymentMethod.mpesa:   return 'mpesa';
      case PaymentMethod.airtel:  return 'airtel';
      case PaymentMethod.paypal:  return 'paypal';
      case PaymentMethod.equity:  return 'equity';
    }
  }

  static PaymentMethod fromString(String value) {
    switch (value) {
      case 'airtel':  return PaymentMethod.airtel;
      case 'paypal':  return PaymentMethod.paypal;
      case 'equity':  return PaymentMethod.equity;
      default:        return PaymentMethod.mpesa;
    }
  }
}

// ── Payment Status Enum ─────────────────────────────────────────
enum PaymentStatus { pending, processing, completed, failed, cancelled }

// ── Payment Model ──────────────────────────────────────────────
class PaymentModel extends Equatable {
  final int id;
  final String transactionId;
  final String checkoutRequestId;
  final double amount;
  final String currency;
  final String phone;
  final String status;
  final PaymentMethod paymentMethod;
  final String? mpesaReceiptNumber;
  final String? receiptNumber;     // unified receipt across gateways
  final String? paypalOrderId;
  final String bookingType;        // 'event' | 'service'
  final int bookingId;
  final DateTime createdAt;
  final DateTime? paidAt;

  const PaymentModel({
    required this.id,
    required this.transactionId,
    required this.checkoutRequestId,
    required this.amount,
    this.currency = 'KES',
    required this.phone,
    required this.status,
    this.paymentMethod = PaymentMethod.mpesa,
    this.mpesaReceiptNumber,
    this.receiptNumber,
    this.paypalOrderId,
    required this.bookingType,
    required this.bookingId,
    required this.createdAt,
    this.paidAt,
  });

  // ── Status helpers ─────────────────────────────────────────
  PaymentStatus get paymentStatus {
    switch (status) {
      case 'completed':  return PaymentStatus.completed;
      case 'processing': return PaymentStatus.processing;
      case 'failed':     return PaymentStatus.failed;
      case 'cancelled':  return PaymentStatus.cancelled;
      default:           return PaymentStatus.pending;
    }
  }

  bool get isCompleted => status == 'completed';
  bool get isFailed    => status == 'failed' || status == 'cancelled';
  bool get isPending   => status == 'pending' || status == 'processing';

  /// Returns the best available receipt number for display
  String get displayReceipt =>
      receiptNumber ?? mpesaReceiptNumber ?? paypalOrderId ?? 'N/A';

  /// Human-readable receipt label based on gateway
  String get receiptLabel => paymentMethod.receiptLabel;

  // ── Serialization ──────────────────────────────────────────
  /// Tolerant numeric parse: the backend may return numbers as JSON numbers
  /// or (via SQLite/PDO) as numeric strings, so handle both to avoid cast errors.
  static num _toNum(dynamic v) =>
      v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id:                   _toNum(json['id']).toInt(),
      transactionId:        json['transaction_id'] as String,
      checkoutRequestId:    json['checkout_request_id'] as String? ?? '',
      amount:               _toNum(json['amount']).toDouble(),
      currency:             json['currency'] as String? ?? 'KES',
      phone:                json['phone'] as String? ?? '',
      status:               json['status'] as String,
      paymentMethod:        PaymentMethod.fromString(json['payment_method'] as String? ?? 'mpesa'),
      mpesaReceiptNumber:   json['mpesa_receipt_number'] as String?,
      receiptNumber:        json['receipt_number'] as String?,
      paypalOrderId:        json['paypal_order_id'] as String?,
      bookingType:          json['booking_type'] as String,
      bookingId:            _toNum(json['booking_id']).toInt(),
      createdAt:            DateTime.parse(json['created_at'] as String),
      paidAt:               json['paid_at'] != null
                                ? DateTime.tryParse(json['paid_at'] as String)
                                : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':                    id,
    'transaction_id':        transactionId,
    'checkout_request_id':   checkoutRequestId,
    'amount':                amount,
    'currency':              currency,
    'phone':                 phone,
    'status':                status,
    'payment_method':        paymentMethod.key,
    'mpesa_receipt_number':  mpesaReceiptNumber,
    'receipt_number':        receiptNumber,
    'paypal_order_id':       paypalOrderId,
    'booking_type':          bookingType,
    'booking_id':            bookingId,
    'created_at':            createdAt.toIso8601String(),
    'paid_at':               paidAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, transactionId, status, paymentMethod];
}
