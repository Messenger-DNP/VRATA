class AuthResponseDto {
  const AuthResponseDto({
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

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      userId: (json['userId'] as num).toInt(),
      username: json['username'] as String,
      tokenType: json['tokenType'] as String,
      accessToken: json['accessToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}
