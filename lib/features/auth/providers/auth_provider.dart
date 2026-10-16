import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/network/dio_client.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

// ── Providers ──────────────────────────────────────────────

final authStateProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

// ── Auth Notifier ──────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<AuthState> {
  final _firebaseAuth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '557938103255-j5737l98e9u8djnpc3n8sld7pqe7o7lr.apps.googleusercontent.com' : null,
  );

  @override
  Future<AuthState> build() async {
    // Listen to Firebase Auth state changes
    final userStream = _firebaseAuth.authStateChanges();
    
    // We get the first event immediately to determine initial state
    final firebaseUser = await userStream.first;
    
    if (firebaseUser == null) {
      return const AuthState();
    }

    return await _fetchUserProfile(firebaseUser);
  }

  Future<AuthState> _fetchUserProfile(User firebaseUser) async {
    final isAdminEmail = firebaseUser.email?.toLowerCase() == 'erickkelwa9@gmail.com';
    try {
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (doc.exists) {
        final userData = doc.data()!;
        userData['id'] = doc.id; // Map document ID to UserModel id
        // Auto-assign admin if email matches master admin
        if (isAdminEmail) {
          userData['role'] = 'admin';
          // Persist admin role to Firestore so it survives across sessions
          if (userData['role'] != 'admin') {
            _firestore
                .collection('users')
                .doc(firebaseUser.uid)
                .update({'role': 'admin'});
          }
        }
        final user = UserModel.fromJson(userData);
        return AuthState(isAuthenticated: true, user: user, token: 'firebase_token');
      } else {
        // No Firestore doc yet — create one
        final user = UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? (isAdminEmail ? 'Admin' : 'User'),
          email: firebaseUser.email ?? '',
          role: isAdminEmail ? 'admin' : 'user',
          createdAt: DateTime.now(),
        );
        // Save document so future lookups work
        _firestore.collection('users').doc(firebaseUser.uid).set(user.toJson());
        return AuthState(isAuthenticated: true, user: user, token: 'firebase_token');
      }
    } catch (e) {
      // Firestore unavailable — build user directly from Firebase Auth data
      // Never return empty AuthState, which would lock the user out
      final user = UserModel(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? (isAdminEmail ? 'Admin' : 'User'),
        email: firebaseUser.email ?? '',
        role: isAdminEmail ? 'admin' : 'user',
        createdAt: DateTime.now(),
      );
      return AuthState(isAuthenticated: true, user: user, token: 'firebase_token');
    }
  }

  // ── Email / Password Login ─────────────────────────────

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        state = AsyncData(await _fetchUserProfile(credential.user!));
      } else {
        state = const AsyncData(AuthState());
      }
    } on FirebaseAuthException catch (e) {
      state = AsyncError(e.message ?? 'Login failed', StackTrace.current);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  // ── Demo Login (auto-creates account if needed) ────────

  static const _demoEmail = 'demo@eventpro.app';
  static const _demoPassword = 'EventPro2026!';
  static const _demoName = 'Demo User';

  Future<void> demoLogin() async {
    state = const AsyncLoading();
    try {
      // Try signing in first
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: _demoEmail,
        password: _demoPassword,
      );
      if (credential.user != null) {
        state = AsyncData(await _fetchUserProfile(credential.user!));
      }
    } on FirebaseAuthException catch (e) {
      // Account doesn't exist → create it
      if (e.code == 'user-not-found' || e.code == 'INVALID_LOGIN_CREDENTIALS' || e.code == 'invalid-credential') {
        try {
          final credential = await _firebaseAuth.createUserWithEmailAndPassword(
            email: _demoEmail,
            password: _demoPassword,
          );
          if (credential.user != null) {
            await credential.user!.updateDisplayName(_demoName);
            final userModel = UserModel(
              id: credential.user!.uid,
              name: _demoName,
              email: _demoEmail,
              role: 'user',
              phone: '+254700000000',
              createdAt: DateTime.now(),
            );
            await _firestore
                .collection('users')
                .doc(credential.user!.uid)
                .set(userModel.toJson());
            state = AsyncData(AuthState(
              isAuthenticated: true,
              user: userModel,
              token: 'firebase_token',
            ));
          }
        } catch (createErr) {
          state = AsyncError(createErr, StackTrace.current);
        }
      } else {
        state = AsyncError(e.message ?? 'Demo login failed', StackTrace.current);
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }



  // ── Register ───────────────────────────────────────────

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    if (password != passwordConfirmation) {
      state = AsyncError('Passwords do not match', StackTrace.current);
      return;
    }
    
    state = const AsyncLoading();
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(name);
        
        // Create user document in Firestore
        final userModel = UserModel(
          id: credential.user!.uid,
          name: name,
          email: email,
          phone: phone,
          role: 'user', // Default role
          createdAt: DateTime.now(),
        );
        
        await _firestore.collection('users').doc(credential.user!.uid).set({
          ...userModel.toJson(),
          'welcome_sent_at': FieldValue.serverTimestamp(),
        });
        
        // Trigger welcome email via Laravel API
        try {
          await DioClient.instance.dio.post('/auth/send-welcome', data: {
            'email': email,
            'name': name,
          });
        } catch (e) {
          debugPrint('Welcome email trigger failed: $e');
        }
        
        state = AsyncData(AuthState(isAuthenticated: true, user: userModel, token: 'firebase_token'));
      }
    } on FirebaseAuthException catch (e) {
      state = AsyncError(e.message ?? 'Registration failed', StackTrace.current);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  // ── Google Sign-In ─────────────────────────────────────

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // On web, use Firebase's built-in popup (no OAuth origin setup needed)
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
      } else {
        // On mobile, use the google_sign_in package
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          state = const AsyncData(AuthState()); // User cancelled
          return;
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _firebaseAuth.signInWithCredential(credential);
      }

      if (userCredential.user != null) {
        // Check if user exists in Firestore
        final doc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        
        UserModel userModel;
        bool needsWelcome = false;

        if (!doc.exists) {
          // First time Google login, create Firestore document
          userModel = UserModel(
            id: userCredential.user!.uid,
            name: userCredential.user!.displayName ?? 'Google User',
            email: userCredential.user!.email ?? '',
            role: 'user',
            createdAt: DateTime.now(),
          );
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({...userModel.toJson(), 'welcome_sent_at': FieldValue.serverTimestamp()});
          needsWelcome = true;
        } else {
          final data = doc.data()!;
          data['id'] = doc.id;
          userModel = UserModel.fromJson(data);
          // Legacy accounts created before the welcome flag — send once
          if (data['welcome_sent_at'] == null &&
              (userModel.email.isNotEmpty)) {
            needsWelcome = true;
            _firestore
                .collection('users')
                .doc(userCredential.user!.uid)
                .update({'welcome_sent_at': FieldValue.serverTimestamp()});
          }
        }

        // Trigger welcome email via Laravel API for new Google signups
        if (needsWelcome && userModel.email.isNotEmpty) {
          try {
            await DioClient.instance.dio.post('/auth/send-welcome', data: {
              'email': userModel.email,
              'name': userModel.name,
            });
          } catch (e) {
            debugPrint('Welcome email trigger failed: $e');
          }
        }
        
        state = AsyncData(AuthState(isAuthenticated: true, user: userModel, token: 'firebase_token'));
      }
    } on FirebaseAuthException catch (e) {
      state = AsyncError(e.message ?? 'Google Sign-In failed', StackTrace.current);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  // ── Forgot Password ────────────────────────────────────

  Future<String> forgotPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return 'Password reset link sent to $email.';
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Failed to send reset email');
    }
  }

  // ── Set / Change Password (also enables it for Google-only accounts) ──

  /// True if the signed-in account already has an Email/Password credential.
  /// Google-only accounts return false until a password is linked.
  Future<bool> hasPasswordProvider() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'password');
  }

  /// Lets the current user create (or change) their password.
  /// For a Google-only account this LINKS an Email/Password credential, which
  /// then makes "Forgot password" email resets work for that account too.
  Future<String> setPassword(String password) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to set a password.');
    }
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw Exception('This account has no email to attach a password to.');
    }
    if (password.length < 8) {
      throw Exception('Password must be at least 8 characters.');
    }
    try {
      final alreadyHasPassword =
          user.providerData.any((p) => p.providerId == 'password');
      if (alreadyHasPassword) {
        await user.updatePassword(password);
        return 'Password updated successfully.';
      }
      // Link Email/Password — the credential's password becomes the account's.
      final credential =
          EmailAuthProvider.credential(email: email, password: password);
      await user.linkWithCredential(credential);
      return 'Password set. You can now sign in with email & password, and use "Forgot password".';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked') {
        try {
          await user.updatePassword(password);
          return 'Password updated successfully.';
        } catch (_) {
          throw Exception(e.message ?? 'Could not set password.');
        }
      }
      if (e.code == 'requires-recent-login') {
        throw Exception(
            'For security, please sign in again before setting a password.');
      }
      throw Exception(e.message ?? 'Could not set password.');
    }
  }

  // ── Admin Session ──────────────────────────────────────

  void setAdminUser({String? name, String? email}) {
    final adminUser = UserModel(
      id: 'admin_1',
      name: name ?? 'Erick Kelwa',
      email: email ?? 'erickkelwa9@gmail.com',
      role: 'admin',
      phone: '+254728664792',
      createdAt: DateTime.now(),
    );
    state = AsyncData(AuthState(
      isAuthenticated: true,
      user: adminUser,
      token: 'admin_sanctum_token',
    ));
  }

  // ── Logout ─────────────────────────────────────────────

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
    state = const AsyncData(AuthState());
  }
}
