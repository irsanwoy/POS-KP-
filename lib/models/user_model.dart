class UserModel {
  final int? id;
  final String username;
  final String password;
  final String role; // contoh: 'kasir' atau 'pemilik'

  UserModel({
    this.id,
    required this.username,
    required this.password,
    required this.role,
  });

  // convert dari map (database) ke object
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      role: map['role'],
    );
  }

  // convert object ke map (untuk insert ke database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role,
    };
  }
}
