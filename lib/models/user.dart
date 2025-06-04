class User {
  int? id;
  String username;
  String email;
  String password;
  String? profilePicturePath;

  User({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    this.profilePicturePath,
  });

  // Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'profile_picture_path': profilePicturePath,
    };
  }

  // Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      password: json['password'],
      profilePicturePath: json['profile_picture_path'],
    );
  }

  @override
  String toString() {
    return 'User{id: $id, username: $username, email: $email}';
  }
}
