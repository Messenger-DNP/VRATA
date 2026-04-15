import 'package:frontend/features/auth/data/dto/auth_response_dto.dart';
import 'package:frontend/features/auth/domain/entities/auth_session.dart';

extension AuthSessionMapper on AuthResponseDto {
  AuthSession toDomain() {
    return AuthSession(
      userId: userId,
      username: username,
      tokenType: tokenType,
      accessToken: accessToken,
      expiresAt: expiresAt,
    );
  }
}
