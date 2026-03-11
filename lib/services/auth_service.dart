import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  User? get currentFirebaseUser => _auth.currentUser;

  // --- AUTH ACTIONS ---

  Future<AppUser> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final doc = await _firestore.collection('users').doc(credential.user!.uid).get();
    if (!doc.exists) throw Exception("User data not found.");
    return AppUser.fromMap(doc.data()!);
  }

  Future<AppUser> signup(String email, String password, String username) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user?.updateDisplayName(username);

    final user = AppUser(
      userID: credential.user!.uid,
      email: email,
      username: username,
      password: password, // Note: Consider removing this for better security later
    );

    await _firestore.collection('users').doc(user.userID).set(user.toMap());
    return user;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // --- PROFILE UPDATE ACTIONS ---

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    // Re-authenticate is mandatory for sensitive changes
    AuthCredential credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    await user.updatePassword(newPassword);

    await _firestore.collection('users').doc(user.uid).update({
      'password': newPassword,
    });
  }

  Future<void> updateUsername(String newUsername) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    await user.updateDisplayName(newUsername);
    await _firestore.collection('users').doc(user.uid).update({
      'username': newUsername,
    });

    await user.reload();
  }

  /// NEW: Handles Profile Picture Upload
  // Future<void> updateProfilePicture(String filePath) async {
  //   final user = _auth.currentUser;
  //   if (user == null) throw Exception("No user logged in");

  //   // 1. Create storage reference
  //   final ref = _storage.ref().child('profile_pics').child('${user.uid}.jpg');

  //   // 2. Upload file
  //   await ref.putFile(File(filePath));

  //   // 3. Get URL
  //   final downloadUrl = await ref.getDownloadURL();

  //   // 4. Update Auth and Firestore
  //   await user.updatePhotoURL(downloadUrl);
  //   await _firestore.collection('users').doc(user.uid).update({
  //     'profileUrl': downloadUrl,
  //   });

  //   await user.reload();
  // }
}