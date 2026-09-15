class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final bool onboardingCompleted;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    required this.onboardingCompleted,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      fullName: json['fullName'],
      avatarUrl: json['avatarUrl'],
      onboardingCompleted: json['onboardingCompleted'] ?? false,
    );
  }
}

class AuthResponse {
  final UserModel user;
  final String accessToken;
  final String refreshToken;

  AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(json['user']),
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
    );
  }
}
