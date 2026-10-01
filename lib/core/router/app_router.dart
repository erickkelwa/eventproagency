import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_routes.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/profile_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/events/screens/home_screen.dart';
import '../../features/events/screens/event_detail_screen.dart';
import '../../features/events/screens/search_screen.dart';
import '../../features/events/screens/my_bookings_screen.dart';
import '../../features/admin/screens/dashboard_screen.dart';
import '../../features/admin/screens/event_list_screen.dart';
import '../../features/admin/screens/create_edit_event_screen.dart';
import '../../features/admin/screens/qr_scanner_screen.dart';
import '../../features/admin/screens/reports_screen.dart';
import '../../features/services/screens/services_home_screen.dart';
import '../../features/services/screens/service_detail_screen.dart';
import '../../features/payment/screens/checkout_screen.dart';
import '../../features/payment/screens/payment_status_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull?.isAuthenticated ?? false;
      final isAdmin = authState.valueOrNull?.isAdmin ?? false;
      final isAuthRoute = [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
        AppRoutes.onboarding,
      ].contains(state.matchedLocation);

      // Not logged in → push to login (except splash & auth routes)
      if (!isLoggedIn &&
          !isAuthRoute &&
          state.matchedLocation != AppRoutes.splash) {
        return AppRoutes.login;
      }

      // Already logged in → redirect away from auth screens
      if (isLoggedIn && isAuthRoute) {
        return isAdmin ? AppRoutes.adminDashboard : AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (c, s) => const SplashScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (c, s) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (c, s) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (c, s) => const RegisterScreen()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (c, s) => const ForgotPasswordScreen()),

      // ── User Routes ──────────────────────────────────────
      GoRoute(path: AppRoutes.home, builder: (c, s) => const HomeScreen()),
      GoRoute(
        path: AppRoutes.eventDetail,
        builder: (c, s) => EventDetailScreen(eventId: s.pathParameters['id']!),
      ),
      GoRoute(path: AppRoutes.search, builder: (c, s) => const SearchScreen()),
      GoRoute(path: AppRoutes.myBookings, builder: (c, s) => const MyBookingsScreen()),
      GoRoute(path: AppRoutes.profile, builder: (c, s) => const ProfileScreen()),
      GoRoute(path: AppRoutes.services, builder: (c, s) => const ServicesHomeScreen()),
      GoRoute(
        path: AppRoutes.serviceDetail,
        builder: (c, s) => ServiceDetailScreen(serviceId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (c, s) => CheckoutScreen(
          bookingType: s.pathParameters['bookingType']!,
          itemId: s.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.paymentStatus,
        builder: (c, s) => PaymentStatusScreen(
          transactionId: s.pathParameters['transactionId']!,
        ),
      ),

      // ── Admin Routes ─────────────────────────────────────
      GoRoute(path: AppRoutes.adminDashboard, builder: (c, s) => const AdminDashboardScreen()),
      GoRoute(path: AppRoutes.adminEvents, builder: (c, s) => const AdminEventListScreen()),
      GoRoute(
        path: AppRoutes.adminEventCreate,
        builder: (c, s) => const CreateEditEventScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminEventEdit,
        builder: (c, s) => CreateEditEventScreen(eventId: s.pathParameters['id']),
      ),
      GoRoute(path: AppRoutes.adminQrScanner, builder: (c, s) => const QrScannerScreen()),
      GoRoute(path: AppRoutes.adminReports, builder: (c, s) => const ReportsScreen()),
    ],
  );
});
