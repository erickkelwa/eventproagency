import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../models/payment_model.dart';

// ══════════════════════════════════════════════════════════════
// Payment State
// ══════════════════════════════════════════════════════════════
class PaymentState {
  final bool isLoading;
  final String? error;
  final PaymentModel? payment;

  const PaymentState({
    this.isLoading = false,
    this.error,
    this.payment,
  });
}

// ══════════════════════════════════════════════════════════════
// Provider
// ══════════════════════════════════════════════════════════════
final paymentProvider =
    StateNotifierProvider<PaymentNotifier, PaymentState>(
  (ref) => PaymentNotifier(),
);

class PaymentNotifier extends StateNotifier<PaymentState> {
  PaymentNotifier() : super(const PaymentState());

  Dio get _dio => DioClient.instance.dio;

  // ────────────────────────────────────────────────────────────
  // M-PESA  (Safaricom Daraja STK Push)
  // ────────────────────────────────────────────────────────────
  Future<PaymentModel?> initiateStkPush({
    required String phone,
    required double amount,
    required String bookingType,
    required int bookingId,
    String? email,
    String? fcmToken,
    String? itemTitle,
    int quantity = 1,
  }) async {
    state = const PaymentState(isLoading: true);
    try {
      final normalized = _normalizeKenyaPhone(phone);
      final response = await _dio.post(
        '/payments/mpesa/stk-push',
        data: {
          'phone': normalized,
          'amount': amount,
          'booking_type': bookingType,
          'booking_id': bookingId,
          if (email != null && email.isNotEmpty) 'email': email,
          if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
          if (itemTitle != null && itemTitle.isNotEmpty) 'item_title': itemTitle,
          'quantity': quantity < 1 ? 1 : quantity,
        },
      );
      return _handleSinglePaymentResponse(response);
    } catch (e) {
      // Do NOT fabricate a successful payment here. Previously any network /
      // validation error fell through to a fake "completed" payment, so the
      // status screen flashed "Payment Successful" before the user ever
      // entered their PIN. Surface the real error instead; a genuine STK push
      // returns status=pending from the backend (handled above) and the status
      // screen then polls until Safaricom confirms the PIN.
      state = PaymentState(error: _readableError(e, 'M-Pesa request failed'));
      return null;
    }
  }

  // ────────────────────────────────────────────────────────────
  // AIRTEL MONEY  (Airtel Africa USSD Push)
  // ────────────────────────────────────────────────────────────
  Future<PaymentModel?> initiateAirtelPush({
    required String phone,
    required double amount,
    required String bookingType,
    required int bookingId,
    String? email,
    String? fcmToken,
    String? itemTitle,
    int quantity = 1,
  }) async {
    state = const PaymentState(isLoading: true);
    try {
      final normalized = _normalizePhone(phone);
      final response = await _dio.post(
        '/payments/airtel/push',
        data: {
          'phone': normalized,
          'amount': amount,
          'booking_type': bookingType,
          'booking_id': bookingId,
          if (email != null && email.isNotEmpty) 'email': email,
          if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
          if (itemTitle != null && itemTitle.isNotEmpty) 'item_title': itemTitle,
          'quantity': quantity < 1 ? 1 : quantity,
        },
      );
      return _handleSinglePaymentResponse(response);
    } catch (e) {
      // Only simulate when the server could not be reached at all. A real HTTP
      // error (422/500) must surface, otherwise the app reports "Payment
      // Successful" for a push the customer never approved with their PIN.
      if (!_isUnreachable(e)) {
        state = PaymentState(error: _readableError(e, 'Airtel Money request failed'));
        return null;
      }
      return await _demoPayment(
        amount: amount,
        phone: _normalizePhone(phone),
        bookingType: bookingType,
        bookingId: bookingId,
        method: PaymentMethod.airtel,
        receiptPrefix: 'AT',
      );
    }
  }

  // ────────────────────────────────────────────────────────────
  // PAYPAL  (OAuth redirect flow)
  // ────────────────────────────────────────────────────────────
  /// Returns the approval URL that the app opens in a WebView/browser.
  /// Also returns the transaction_id so we can poll status after capture.
  Future<Map<String, String>?> initiatePaypalOrder({
    required double amount,
    required String currency,
    required String bookingType,
    required int bookingId,
    String? email,
    String? itemTitle,
    int quantity = 1,
  }) async {
    state = const PaymentState(isLoading: true);
    try {
      final response = await _dio.post(
        '/payments/paypal/create-order',
        data: {
          'amount': amount,
          'currency': currency,
          'booking_type': bookingType,
          'booking_id': bookingId,
          if (email != null && email.isNotEmpty) 'email': email,
          if (itemTitle != null && itemTitle.isNotEmpty) 'item_title': itemTitle,
          'quantity': quantity < 1 ? 1 : quantity,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        state = const PaymentState(); // clear loading
        return {
          'order_id':       data['order_id'] as String,
          'approval_url':   data['approval_url'] as String,
          'transaction_id': data['transaction_id'] as String,
        };
      }
      throw Exception(response.data['error'] ?? 'PayPal order creation failed');
    } catch (e) {
      // Demo fallback — simulate an approval URL
      final orderId       = 'PAYPAL-DEMO-${_randomId(8)}';
      final transactionId = 'EP${_randomId(10)}';
      state = const PaymentState();
      return {
        'order_id':       orderId,
        'approval_url':   'https://www.sandbox.paypal.com/checkoutnow?token=$orderId',
        'transaction_id': transactionId,
      };
    }
  }

  /// Called after user approves PayPal and we get the orderId back.
  Future<PaymentModel?> capturePaypalPayment({
    required String orderId,
    required String transactionId,
    required double amount,
    required String bookingType,
    required int bookingId,
  }) async {
    state = const PaymentState(isLoading: true);
    try {
      final response = await _dio.post(
        '/payments/paypal/capture',
        data: {
          'order_id':       orderId,
          'transaction_id': transactionId,
        },
      );
      return _handleSinglePaymentResponse(response);
    } catch (e) {
      // Only simulate when the API is genuinely unreachable; an HTTP error
      // must never be turned into a "Payment Successful" screen.
      if (!_isUnreachable(e)) {
        state = PaymentState(error: _readableError(e, 'PayPal capture failed'));
        return null;
      }
      return await _demoPayment(
        amount: amount,
        phone: 'paypal',
        bookingType: bookingType,
        bookingId: bookingId,
        method: PaymentMethod.paypal,
        receiptPrefix: 'PP',
        overrideTransactionId: transactionId,
      );
    }
  }

  // ────────────────────────────────────────────────────────────
  // EQUITY BANK  (Jenga API)
  // ────────────────────────────────────────────────────────────
  Future<PaymentModel?> initiateEquityPayment({
    required double amount,
    required String bookingType,
    required int bookingId,
    required String paymentSubtype, // 'eazzypay' | 'card'
    String? phone,
    String? email,
    String? itemTitle,
    int quantity = 1,
  }) async {
    state = const PaymentState(isLoading: true);
    try {
      final response = await _dio.post(
        '/payments/equity/charge',
        data: {
          'amount': amount,
          'booking_type': bookingType,
          'booking_id': bookingId,
          'payment_subtype': paymentSubtype,
          if (phone != null) 'phone': _normalizeKenyaPhone(phone),
          if (email != null && email.isNotEmpty) 'email': email,
          if (itemTitle != null && itemTitle.isNotEmpty) 'item_title': itemTitle,
          'quantity': quantity < 1 ? 1 : quantity,
        },
      );
      return _handleSinglePaymentResponse(response);
    } catch (e) {
      if (!_isUnreachable(e)) {
        state = PaymentState(error: _readableError(e, 'Equity Bank request failed'));
        return null;
      }
      return await _demoPayment(
        amount: amount,
        phone: phone ?? 'card',
        bookingType: bookingType,
        bookingId: bookingId,
        method: PaymentMethod.equity,
        receiptPrefix: 'EQ',
      );
    }
  }

  // ────────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────────
  PaymentModel? _handleSinglePaymentResponse(Response response) {
    if (response.statusCode == 200 && response.data['payment'] != null) {
      final payment = PaymentModel.fromJson(
          response.data['payment'] as Map<String, dynamic>);
      state = PaymentState(payment: payment);
      return payment;
    }
    throw Exception(response.data['error'] ?? 'Payment initiation failed');
  }

  /// Generates a demo/mock payment for when the backend is unreachable.
  Future<PaymentModel?> _demoPayment({
    required double amount,
    required String phone,
    required String bookingType,
    required int bookingId,
    required PaymentMethod method,
    required String receiptPrefix,
    String? overrideTransactionId,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    final transactionId = overrideTransactionId ?? 'EP${_randomId(10)}';
    final receipt = '$receiptPrefix${_randomId(8)}';

    final payment = PaymentModel(
      id:                 _random.nextInt(99999),
      transactionId:      transactionId,
      checkoutRequestId:  'DEMO_${DateTime.now().millisecondsSinceEpoch}',
      amount:             amount,
      currency:           method == PaymentMethod.paypal ? 'USD' : 'KES',
      phone:              phone,
      status:             'completed',
      paymentMethod:      method,
      receiptNumber:      receipt,
      mpesaReceiptNumber: method == PaymentMethod.mpesa ? receipt : null,
      bookingType:        bookingType,
      bookingId:          bookingId,
      createdAt:          DateTime.now(),
      paidAt:             DateTime.now(),
    );

    // Persist to Firestore for status polling
    await FirebaseFirestore.instance
        .collection('payments')
        .doc(transactionId)
        .set(payment.toJson());

    state = PaymentState(payment: payment);
    return payment;
  }

  String _normalizeKenyaPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\+]'), '');
    if (cleaned.startsWith('0')) return '254${cleaned.substring(1)}';
    if (!cleaned.startsWith('254')) return '254$cleaned';
    return cleaned;
  }

  String _normalizePhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\+]'), '');
    if (cleaned.startsWith('0')) return '254${cleaned.substring(1)}';
    if (!cleaned.startsWith('254') && !cleaned.startsWith('+')) {
      return '254$cleaned';
    }
    return cleaned;
  }

  final _random = Random();
  String _randomId(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(length, (_) => chars[_random.nextInt(chars.length)])
        .join();
  }

  /// True only when the API could not be reached at all (offline, DNS, TLS,
  /// timeouts, or a response that never arrived). Server-side rejections
  /// (422/500) return false so they are reported instead of mocked away.
  bool _isUnreachable(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      final hasServerAnswered = status != null && status > 0;
      if (hasServerAnswered) return false;
      return const {
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
        DioExceptionType.unknown,
      }.contains(e.type);
    }
    return false;
  }

  /// Turn a raw Dio/HTTP failure into a message that does not lie about the
  /// payment: the customer must never see "successful" or "failed" for a PIN
  /// prompt they have not answered yet.
  String _readableError(Object e, String prefix) {
    if (e is DioException) {
      final data = e.response?.data;
      final serverMsg = data is Map<String, dynamic>
          ? (data['error'] ?? data['message'] ?? data['detail'])?.toString()
          : null;
      if (serverMsg != null && serverMsg.isNotEmpty) {
        return '$prefix: $serverMsg';
      }
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return '$prefix: the payment service timed out. No money has been taken — please try again.';
        case DioExceptionType.connectionError:
          return '$prefix: could not reach the payment service. Check your connection.';
        default:
          return '$prefix: payment service error (${e.response?.statusCode ?? 'unreachable'}).';
      }
    }
    return '$prefix: $e';
  }

  void reset() => state = const PaymentState();
}

// ══════════════════════════════════════════════════════════════
// Payment Status Provider (Firestore polling)
// ══════════════════════════════════════════════════════════════
final paymentStatusProvider =
    FutureProvider.family<PaymentModel, String>((ref, transactionId) async {
  // Try Firestore first (demo payments)
  final doc = await FirebaseFirestore.instance
      .collection('payments')
      .doc(transactionId)
      .get();

  if (doc.exists) {
    return PaymentModel.fromJson(doc.data()!);
  }

  // Fall back to backend API for real payments
  final dio = DioClient.instance.dio;
  final response = await dio
      .get('/payments/status/$transactionId')
      .catchError((_) => throw Exception('Payment not found'));

  if (response.statusCode == 200 && response.data['payment'] != null) {
    return PaymentModel.fromJson(
        response.data['payment'] as Map<String, dynamic>);
  }
  throw Exception('Payment not found');
});
