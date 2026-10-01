import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
    try {
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      
      if (doc.exists) {
        final userData = doc.data()!;
        userData['id'] = doc.id; // Map document ID to UserModel id
        final user = UserModel.fromJson(userData);
        return AuthState(isAuthenticated: true, user: user, token: 'firebase_token');
      } else {
        // Fallback if document doesn't exist yet
        final user = UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'User',
          email: firebaseUser.email ?? '',
          role: 'user',
          createdAt: DateTime.now(),
        );
        return AuthState(isAuthenticated: true, user: user, token: 'firebase_token');
      }
    } catch (e) {
      return const AuthState();
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
        
        await _firestore.collection('users').doc(credential.user!.uid).set(userModel.toJson());
        
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
        
        if (!doc.exists) {
          // First time Google login, create Firestore document
          userModel = UserModel(
            id: userCredential.user!.uid,
            name: userCredential.user!.displayName ?? 'Google User',
            email: userCredential.user!.email ?? '',
            role: 'user',
            createdAt: DateTime.now(),
          );
          await _firestore.collection('users').doc(userCredential.user!.uid).set(userModel.toJson());
        } else {
          final data = doc.data()!;
          data['id'] = doc.id;
          userModel = UserModel.fromJson(data);
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

  // ── Logout ─────────────────────────────────────────────

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
    state = const AsyncData(AuthState());
  }
}
