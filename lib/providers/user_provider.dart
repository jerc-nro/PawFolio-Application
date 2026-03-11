import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AppUser? _user;
  bool _isLoading = true;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  UserProvider() {
    _initializeUser();
  }

  void _initializeUser() {
    // This listener triggers whenever the user signs in, signs out, 
    // or when updateDisplayName/updatePassword is called + reload()
    _auth.userChanges().listen((User? firebaseUser) {
      if (firebaseUser != null) {
        _user = AppUser(
          userID: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          username: firebaseUser.displayName ?? 'User',
          password: '', 
        );
      } else {
        _user = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  // --- EXISTING METHODS ---

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.login(email, password);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signup(String email, String password, String username) async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authService.signup(email, password, username);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- NEW UPDATE METHODS ---

  Future<void> updateUsername(String newName) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.updateUsername(newName);
      // userChanges() listener will automatically update the _user object
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePassword(String current, String next) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.updatePassword(current, next);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      _user = null;
      notifyListeners();
    } catch (e) {
      debugPrint("Logout error: $e");
    }
  }

 void _setLoading(bool val) {
  _isLoading = val;
  notifyListeners();
}

Future<void> pickAndUploadProfileImage() async {
  final picker = ImagePicker();
  final XFile? image = await picker.pickImage(
    source: ImageSource.gallery, 
    imageQuality: 50, // Keeps file size small for Firebase Storage
  );

  if (image == null) return; 

//   _setLoading(true);
//   try {
//     // We send the path to the service to handle the Firebase upload
//     await _authService.updateProfilePicture(image.path);
//     // The userChanges() listener in your constructor will handle the UI update
//   } catch (e) {
//     debugPrint("Upload error: $e");
//     rethrow;
//   } finally {
//     _setLoading(false);
//   }
// }
}
}