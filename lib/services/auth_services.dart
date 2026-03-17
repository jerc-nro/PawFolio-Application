import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isSigningIn = false;

  Stream<User?> get currentFirebaseUserStream => _auth.authStateChanges();
  String? get currentUid => _auth.currentUser?.uid;
  User? get currentUser => _auth.currentUser;

  // --- FETCH DATA ---

  Future<AppUser?> getAppUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      final userModel = AppUser.fromMap(doc.data()!, doc.id);
      return userModel.copyWith(
        emailVerified: _auth.currentUser?.emailVerified ?? false,
      );
    }
    return null;
  }

  // --- GOOGLE SIGN IN ---
  // Returns the AppUser directly so auth_provider can set state immediately
  // without going through the email-verification stream check.

  Future<AppUser?> signInWithGoogle() async {
    if (_isSigningIn) return null;
    _isSigningIn = true;

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        final newUser = AppUser(
          userID: user.uid,
          email: user.email ?? '',
          username: user.displayName ?? 'New User',
          photoUrl: user.photoURL,
          emailVerified: true,
        );
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        return newUser;
      } else {
        final existingUser = AppUser.fromMap(doc.data()!, doc.id);
        return existingUser.copyWith(emailVerified: true);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred during Google Sign-In.';
    } finally {
      _isSigningIn = false;
    }
  }

  // --- AUTH STATE SYNC ---
  

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

  // --- EMAIL/PASSWORD ---

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signup(String email, String password, String username) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = AppUser(
      userID: credential.user!.uid,
      email: email,
      username: username,
      emailVerified: false,
    );
    await _firestore.collection('users').doc(user.userID).set(user.toMap());
    await credential.user?.updateDisplayName(username);
  }

  // --- VERIFICATION & RESET ---

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // --- PROFILE UPDATES ---

  Future<bool> updateUsername(String name) async {
    try {
      final uid = currentUid;
      if (uid == null) return false;
      await _auth.currentUser?.updateDisplayName(name);
      await _firestore.collection('users').doc(uid).update({'username': name});
      await reloadUser();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProfilePictureBase64(String base64) async {
    try {
      final uid = currentUid;
      if (uid == null) return false;
      await _firestore.collection('users').doc(uid).update({
        'profileBase64': base64,
        'photoUrl': null,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- EXIT ACTIONS ---

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
