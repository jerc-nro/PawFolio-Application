import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

/// Result from Google sign-in — carries both the user and whether
/// this was a brand-new account creation.
class GoogleSignInResult {
  final AppUser user;
  final bool isNewUser;
  const GoogleSignInResult({required this.user, required this.isNewUser});
}

class AuthService {
  final FirebaseAuth _auth         = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isSigningIn = false;

  Stream<User?> get currentFirebaseUserStream => _auth.authStateChanges();
  String? get currentUid  => _auth.currentUser?.uid;
  User?   get currentUser => _auth.currentUser;

  // ── Fetch user data ────────────────────────────────────────────────────────

  Future<AppUser?> getAppUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap(doc.data()!, doc.id).copyWith(
        emailVerified: _auth.currentUser?.emailVerified ?? false,
      );
    }
    return null;
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  Future<GoogleSignInResult?> signInWithGoogle() async {
    if (_isSigningIn) return null;
    _isSigningIn = true;
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth  = await googleUser.authentication;
      final credential  = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user           = userCredential.user;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        // Brand-new Google user
        final newUser = AppUser(
          userID:        user.uid,
          email:         user.email ?? '',
          username:      user.displayName ?? 'New User',
          photoUrl:      user.photoURL,
          emailVerified: true,
        );
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(newUser.toMap());
        return GoogleSignInResult(user: newUser, isNewUser: true);
      } else {
        final existing = AppUser.fromMap(doc.data()!, doc.id)
            .copyWith(emailVerified: true);
        return GoogleSignInResult(user: existing, isNewUser: false);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred during Google Sign-In.';
    } finally {
      _isSigningIn = false;
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'Account already exists with a different login method.';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  // ── Email/Password ─────────────────────────────────────────────────────────

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future<void> signup(
      String email, String password, String username) async {
    final credential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final user = AppUser(
      userID:        credential.user!.uid,
      email:         email,
      username:      username,
      emailVerified: false,
    );
    await _firestore
        .collection('users')
        .doc(user.userID)
        .set(user.toMap());
    await credential.user?.updateDisplayName(username);
  }

  // ── Verification & reset ───────────────────────────────────────────────────

  Future<void> sendEmailVerification() async =>
      _auth.currentUser?.sendEmailVerification();

  Future<void> sendPasswordResetEmail(String email) async =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> reloadUser() async => _auth.currentUser?.reload();

  // ── Profile updates ────────────────────────────────────────────────────────

  Future<bool> updateUsername(String name) async {
    try {
      final uid = currentUid;
      if (uid == null) return false;
      await _auth.currentUser?.updateDisplayName(name);
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'username': name});
      await reloadUser();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateProfilePictureBase64(String base64) async {
    try {
      final uid = currentUid;
      if (uid == null) return false;
      await _firestore.collection('users').doc(uid).update({
        'profileBase64': base64,
        'photoUrl':      null,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Exit ───────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> deleteUserAccount(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      final user = _auth.currentUser;
      if (user != null) await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'Please log out and log back in before deleting your account.';
      }
      rethrow;
    }
  }
}