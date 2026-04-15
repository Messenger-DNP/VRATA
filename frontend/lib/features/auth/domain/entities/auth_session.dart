class AuthSession {
  const AuthSession({
    required this.userId,
    required this.username,
    required this.tokenType,
    required this.accessToken,
    required this.expiresAt,
  });

  final int userId;
  final String username;
  final String tokenType;
  final String accessToken;
  final DateTime expiresAt;
}
