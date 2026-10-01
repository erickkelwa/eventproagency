/// EventPro App Route Names (GoRouter)
class AppRoutes {
  AppRoutes._();

  // ── Auth ──────────────────────────────────────────────────
  static const String splash         = '/';
  static const String onboarding     = '/onboarding';
  static const String login          = '/login';
  static const String register       = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword  = '/reset-password';

  // ── User Shell ────────────────────────────────────────────
  static const String home          = '/home';
  static const String eventDetail   = '/events/:id';
  static const String search        = '/search';
  static const String myBookings    = '/my-bookings';
  static const String services      = '/services';
  static const String serviceDetail = '/services/:id';
  static const String profile       = '/profile';

  // ── Payment Flow ──────────────────────────────────────────
  /// Entry point — payment method selector (replaces old checkout)
  static const String paymentMethod = '/payment/:bookingType/:id';
  /// Method-specific checkout screens (reached via PaymentMethodScreen)
  static const String checkout      = '/checkout/:bookingType/:id';
  /// Payment status / confirmation screen
  static const String paymentStatus = '/payment-status/:transactionId';

  // ── Admin Shell ───────────────────────────────────────────
  static const String adminDashboard  = '/admin/dashboard';
  static const String adminEvents     = '/admin/events';
  static const String adminEventCreate= '/admin/events/create';
  static const String adminEventEdit  = '/admin/events/:id/edit';
  static const String adminQrScanner  = '/admin/qr-scanner';
  static const String adminReports    = '/admin/reports';
  static const String adminTransactions = '/admin/transactions';
}
