import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles FCM permission, device-token retrieval and persistence.
///
/// The token is stored in Firestore on the user document (`fcm_token`) so the
/// backend can send a payment-success push, and cached locally in
/// SharedPreferences so the payment flow can attach it without an async read.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Required only for web push. Get a Web Push certificate (VAPID key) from
  /// Firebase Console → Cloud Messaging → Web Push certificates.
  static const String webVapidKey = String.fromEnvironment(
    'FIREBASE_WEB_VAPID_KEY',
    defaultValue: '',
  );

  static const String _tokenKey = 'device_fcm_token';

  /// Last known device token (may be null until [ensureToken] runs).
  static String? cachedToken;

  bool _initialized = false;

  /// Request permission and obtain the device token. Safe to call repeatedly.
  Future<String?> ensureToken() async {
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return null;
      }

      // On web a VAPID key is mandatory; skip gracefully if not configured.
      if (kIsWeb && webVapidKey.isEmpty) {
        debugPrint('FCM web token skipped: FIREBASE_WEB_VAPID_KEY not set.');
        return null;
      }

      final token = await messaging.getToken(
        vapidKey: kIsWeb ? webVapidKey : null,
      );
      if (token != null && token.isNotEmpty) {
        cachedToken = token;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
      }

      // Keep the cached token fresh when Firebase rotates it.
      if (!_initialized) {
        messaging.onTokenRefresh.listen((newToken) async {
          cachedToken = newToken;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, newToken);
        });
        _initialized = true;
      }

      return token;
    } catch (e) {
      debugPrint('NotificationService.ensureToken failed: $e');
      return null;
    }
  }

  /// Load a previously cached token at startup (before the async fetch finishes).
  Future<void> loadCachedToken() async {
    final prefs = await SharedPreferences.getInstance();
    cachedToken = prefs.getString(_tokenKey);
  }

  /// Persist the token onto the authenticated user's Firestore document.
  Future<String?> saveTokenForUser(String uid) async {
    final token = await ensureToken();
    if (token == null) return null;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'fcm_token': token}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to save FCM token to Firestore: $e');
    }
    return token;
  }
}
