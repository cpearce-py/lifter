class UserProfile {
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? email;

  UserProfile({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.email,
  });

  UserProfile copyWith({
    int? id,
    String? username,
    String? firstName,
    String? lastName,
    String? email,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': id,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'update_time': DateTime.now().toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['user_id'] as int,
      username: map['username'] as String,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      email: map['email'] as String?,
    );
  }
}
