import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/theme_provider.dart';
import 'core/network/dio_client.dart';
import 'core/services/notification_service.dart';
import 'core/router/app_router.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── System UI Overlay ────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0B14),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Portrait + Landscape (allow all)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Firebase Init ────────────────────────────────────────
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Dio HTTP Client ──────────────────────────────────────
  DioClient.instance.init();

  // ── Push notifications (FCM) ─────────────────────────────
  // Restore any cached device token immediately, then request permission and
  // refresh it in the background (non-blocking) so payment pushes can be sent.
  await NotificationService.instance.loadCachedToken();
  // ignore: unawaited_futures, discarded_futures
  NotificationService.instance.ensureToken();

  runApp(
    const ProviderScope(
      child: EventProApp(),
    ),
  );
}

class EventProApp extends ConsumerWidget {
  const EventProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    // Update global static colors before building theme
    AppColors.setTheme(themeMode == ThemeMode.dark);

    return MaterialApp.router(
      title: 'EventPro',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
