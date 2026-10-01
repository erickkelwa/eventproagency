import 'package:flutter/foundation.dart';

/// EventPro API Route Constants
class ApiConstants {
  ApiConstants._();

  // ── Base URLs ─────────────────────────────────────────────
  static const String localBaseUrl      = 'http://192.168.1.209:8000/api';
  static const String localBaseUrlIos   = 'http://127.0.0.1:8000/api';
  static const String productionBaseUrl = 'https://us-central1-YOUR_PROJECT.cloudfunctions.net/api';
  static const String ngrokBaseUrl      = 'https://errant-catnap-paparazzi.ngrok-free.dev/api';

  // Use ngrokBaseUrl to test on phone without WiFi, localBaseUrl for same-WiFi testing
  static const String baseUrl = kIsWeb ? 'http://127.0.0.1:8000/api' : ngrokBaseUrl;

  // ── Timeouts ──────────────────────────────────────────────
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // ── Auth Endpoints ────────────────────────────────────────
  static const String register       = '/auth/register';
  static const String login          = '/auth/login';
  static const String googleLogin    = '/auth/google';
  static const String logout         = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword  = '/auth/reset-password';
  static const String updatePassword = '/auth/update-password';
  static const String me             = '/auth/me';

  // ── Events (Public) ───────────────────────────────────────
  static const String events          = '/events';
  static const String eventDetail     = '/events/{id}';
  static const String eventCategories = '/events/categories';

  // ── Admin Endpoints ───────────────────────────────────────
  static const String adminDashboard    = '/admin/dashboard';
  static const String adminEvents       = '/admin/events';
  static const String adminEventCreate  = '/admin/events';
  static const String adminCheckIn      = '/admin/check-in';
  static const String adminReports      = '/admin/reports';
  static const String adminTransactions = '/admin/transactions';

  // ── Bookings ──────────────────────────────────────────────
  static const String bookings       = '/bookings';
  static const String myBookings     = '/bookings/my';
  static const String bookingDetail  = '/bookings/{id}';

  // ── Services (Agency) ─────────────────────────────────────
  static const String services           = '/services';
  static const String serviceDetail      = '/services/{id}';
  static const String serviceBookings    = '/service-bookings';
  static const String myServiceBookings  = '/service-bookings/my';

  // ── Payments — M-Pesa ─────────────────────────────────────
  static const String mpesaStkPush = '/payments/mpesa/stk-push';
  static const String mpesaStatus  = '/payments/mpesa/status/{id}';

  // ── Payments — Airtel Money ───────────────────────────────
  static const String airtelPush = '/payments/airtel/push';

  // ── Payments — PayPal ─────────────────────────────────────
  static const String paypalCreateOrder = '/payments/paypal/create-order';
  static const String paypalCapture     = '/payments/paypal/capture';

  // ── Payments — Equity Bank (Jenga) ────────────────────────
  static const String equityCharge = '/payments/equity/charge';

  // ── Payments — Paystack ───────────────────────────────────
  static const String paystackInitialize = '/payments/paystack/initialize';
  static const String paystackCallback   = '/payments/paystack/callback';

  // ── Payments — Generic ────────────────────────────────────
  static const String paymentStatus  = '/payments/status/{id}';
  static const String downloadReceipt = '/payments/receipt/{id}';

  // ── Notifications ─────────────────────────────────────────
  static const String updateFcmToken = '/user/fcm-token';
  static const String notifications  = '/notifications';
}
