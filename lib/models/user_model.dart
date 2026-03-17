import 'package:flutter/foundation.dart';

@immutable
class AppUser {
  final String userID;
  final String email;
  final String username;
  final String? photoUrl;
  final String? profileBase64;
  final bool emailVerified; // Field exists

  const AppUser({
    required this.userID,
    required this.email,
    required this.username,
    this.photoUrl,
    this.profileBase64,
    this.emailVerified = false, // Add default value to constructor
  });

  // Updated copyWith to include emailVerified
  AppUser copyWith({
    String? userID,
    String? email,
    String? username,
    ValueGetter<String?>? photoUrl,
    ValueGetter<String?>? profileBase64,
    bool? emailVerified, // Add this parameter
  }) {
    return AppUser(
      userID: userID ?? this.userID,
      email: email ?? this.email,
      username: username ?? this.username,
      photoUrl: photoUrl != null ? photoUrl() : this.photoUrl,
      profileBase64: profileBase64 != null ? profileBase64() : this.profileBase64,
      emailVerified: emailVerified ?? this.emailVerified, // Logic to update field
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> data, String documentId) {
    return AppUser(
      userID: documentId,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      photoUrl: data['photoUrl'] as String?,
      profileBase64: data['profileBase64'] as String?,
      // Safe check: if Firestore doesn't have this field yet, default to false
      emailVerified: data['emailVerified'] ?? false, 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'photoUrl': photoUrl,
      'profileBase64': profileBase64,
      'emailVerified': emailVerified, // Keep Firestore in sync
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          userID == other.userID &&
          email == other.email &&
          username == other.username &&
          photoUrl == other.photoUrl &&
          profileBase64 == other.profileBase64 &&
          emailVerified == other.emailVerified; // Include in equality

  @override
  int get hashCode =>
      userID.hashCode ^
      email.hashCode ^
      username.hashCode ^
      photoUrl.hashCode ^
      profileBase64.hashCode ^
      emailVerified.hashCode; // Include in hashCode
}