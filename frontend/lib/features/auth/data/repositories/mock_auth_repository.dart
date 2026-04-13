import 'package:frontend/features/auth/data/datasources/mock_auth_datasource.dart';
import 'package:frontend/features/auth/data/dto/login_request_dto.dart';
import 'package:frontend/features/auth/data/dto/register_request_dto.dart';
import 'package:frontend/features/auth/data/mappers/auth_session_mapper.dart';
import 'package:frontend/features/auth/domain/entities/auth_failure.dart';
import 'package:frontend/features/auth/domain/entities/auth_session.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  const MockAuthRepository(this._datasource);

  final MockAuthDatasource _datasource;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _datasource.login(
        LoginRequestDto(username: username, password: password),
      );

      return response.toDomain();
    } on MockAuthException catch (exception) {
      throw AuthFailureException(_mapFailure(exception.code));
    }
  }

  @override
  Future<AuthSession> register({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _datasource.register(
        RegisterRequestDto(username: username, password: password),
      );

      return response.toDomain();
    } on MockAuthException catch (exception) {
      throw AuthFailureException(_mapFailure(exception.code));
    }
  }

  AuthFailure _mapFailure(MockAuthErrorCode code) {
    switch (code) {
      case MockAuthErrorCode.invalidCredentials:
        return const InvalidCredentialsFailure();
      case MockAuthErrorCode.userAlreadyExists:
        return const UserAlreadyExistsFailure();
    }
  }
}
