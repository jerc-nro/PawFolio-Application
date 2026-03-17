import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_services.dart';
import '../../../services/picker_services.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? localBase64;
  final String? error;
  final bool isSigningUp;
  final bool rememberMe;
  final bool isInitializing;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.localBase64,
    this.error,
    this.isSigningUp = false,
    this.rememberMe = false,
    this.isInitializing = false,
  });

  factory AuthState.initial() => const AuthState(isLoading: true, isInitializing: true);

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? localBase64,
    String? error,
    bool? isSigningUp,
    bool? rememberMe,
    bool? isInitializing,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      localBase64: localBase64 ?? this.localBase64,
      error: clearError ? null : (error ?? this.error),
      isSigningUp: isSigningUp ?? this.isSigningUp,
      rememberMe: rememberMe ?? this.rememberMe,
      isInitializing: isInitializing ?? this.isInitializing,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  StreamSubscription? _authSubscription;
  static const String _imgKey = 'user_profile_image';
  static const String _rememberKey = 'remember_device';

  // Tracks whether we are in an active sign-in flow so the stream
  // does NOT apply the "remember me" cold-start logout check.
  bool _isActivelySigningIn = false;

  AuthNotifier(this._authService) : super(AuthState.initial()) {
    _initialize();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> toggleRememberMe(bool value) async {
    state = state.copyWith(rememberMe: value);
    // Persist immediately so it survives app restarts
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberKey, value);
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final shouldRemember = prefs.getBool(_rememberKey) ?? false;
    state = state.copyWith(rememberMe: shouldRemember);

    _authSubscription = _authService.currentFirebaseUserStream.listen((firebaseUser) async {
      if (state.isSigningUp) return;

      if (firebaseUser == null) {
        state = state.copyWith(user: null, isLoading: false, isInitializing: false, clearError: true);
        return;
      }

      // Only apply the "remember me" cold-start logout on the very first
      // stream event (state.isLoading == true) AND when no active sign-in
      // flow is in progress. This prevents kicking out a user who just
      // completed Google / email sign-in.
      if (!shouldRemember && state.isLoading && !_isActivelySigningIn) {
        await signOut();
        return;
      }

      await _authService.reloadUser();
      final refreshedUser = _authService.currentUser;

      if (refreshedUser == null) {
        state = state.copyWith(user: null, isLoading: false, isInitializing: false);
        return;
      }

      final isGoogleUser = refreshedUser.providerData
          .any((p) => p.providerId == 'google.com');

      if (!isGoogleUser && !refreshedUser.emailVerified) {
        await _authService.logout();
        state = state.copyWith(
          user: null,
          isLoading: false,
          isInitializing: false,
          error: "Please verify your email before logging in.",
        );
        return;
      }

      try {
        final userData = await _authService.getAppUserData(refreshedUser.uid);
        if (userData == null) {
          state = state.copyWith(
            user: null,
            isLoading: false,
            isInitializing: false,
            error: "No account found. Please Sign Up first.",
          );
          return;
        }
        state = AuthState(user: userData, isLoading: false, isInitializing: false, rememberMe: shouldRemember);
      } catch (e) {
        state = state.copyWith(user: null, isLoading: false, error: "Sync error: $e");
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    _isActivelySigningIn = true;
    try {
      await _authService.login(email, password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberKey, state.rememberMe);
    } catch (e) {
      String msg = "Incorrect credentials. If you signed up with Google, use the Google button.";
      final err = e.toString().toLowerCase();
      if (err.contains('too-many-requests')) msg = "Too many attempts. Try again later.";
      state = state.copyWith(user: null, isLoading: false, error: msg);
    } finally {
      _isActivelySigningIn = false;
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    _isActivelySigningIn = true;
    try {
      final appUser = await _authService.signInWithGoogle();
      if (appUser == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberKey, state.rememberMe);
      state = AuthState(user: appUser, isLoading: false, rememberMe: state.rememberMe);
    } catch (e) {
      state = state.copyWith(user: null, isLoading: false, error: e.toString());
    } finally {
      _isActivelySigningIn = false;
    }
  }

  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_imgKey);
      await prefs.setBool(_rememberKey, false);
      await _authService.logout();
      state = const AuthState(user: null, isLoading: false, rememberMe: false);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // --- SIGN UP ---
  Future<void> signUp(String email, String password, String name) async {
    state = const AuthState(isLoading: true, isSigningUp: true);
    try {
      await _authService.signup(email, password, name);
      await _authService.sendEmailVerification();
      await _authService.logout();
      state = const AuthState(isLoading: false, isSigningUp: false);
    } catch (e) {
      String msg = "Sign up failed. Please try again.";
      final err = e.toString();
      if (err.contains('email-already-in-use')) {
        msg = "An account with this email already exists.";
      } else if (err.contains('weak-password')) {
        msg = "Password is too weak. Use at least 8 characters.";
      } else if (err.contains('invalid-email')) {
        msg = "Please enter a valid email address.";
      }
      state = AuthState(isLoading: false, isSigningUp: false, error: msg);
      rethrow;
    }
  }

  // --- HELPERS ---

  Future<void> sendEmailVerification() async {
    try {
      await _authService.sendEmailVerification();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> refreshUserStatus() async {
    final uid = state.user?.userID;
    if (uid == null) return;
    try {
      await _authService.reloadUser();
      final data = await _authService.getAppUserData(uid);
      state = state.copyWith(user: data);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> updateUsername(String name) async {
    state = state.copyWith(isLoading: true);
    try {
      final success = await _authService.updateUsername(name);
      if (success) {
        state = state.copyWith(
          user: state.user?.copyWith(username: name),
          isLoading: false,
        );
      }
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> pickAndUploadProfileImage() async {
    state = state.copyWith(isLoading: true);
    try {
      final base64 = await PickerService.pickImageAsBase64();
      if (base64 == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_imgKey, base64);
      final success = await _authService.updateProfilePictureBase64(base64);
      if (success) {
        state = state.copyWith(
          user: state.user?.copyWith(
            profileBase64: () => base64,
            photoUrl: () => null,
          ),
          localBase64: base64,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true);
    try {
      final uid = state.user?.userID;
      if (uid == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_imgKey);
      await _authService.deleteUserAccount(uid);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}