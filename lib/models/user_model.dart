class AppUser {
  String userID;
  String username;
  String email;
  String password;

  AppUser({
    required this.userID,
    required this.username,
    required this.email,
    required this.password,
  });


  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      userID: data['uid'],
      email: data['email'],
      username: data['username'],
      password: data['password']
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': userID,
      'email': email,
      'username': username,
      'password': password
    };
  }
} 