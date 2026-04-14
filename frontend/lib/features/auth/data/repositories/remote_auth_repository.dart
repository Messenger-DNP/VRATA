import 'package:frontend/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:frontend/features/auth/data/dto/login_request_dto.dart';
import 'package:frontend/features/auth/data/dto/register_request_dto.dart';
import 'package:frontend/features/auth/data/mappers/auth_session_mapper.dart';
import 'package:frontend/features/auth/domain/entities/auth_failure.dart';
import 'package:frontend/features/auth/domain/entities/auth_session.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';

class RemoteAuthRepository implements AuthRepository {
  const RemoteAuthRepository(this._datasource);

  final AuthRemoteDatasource _datasource;

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
    } on AuthRemoteException catch (exception) {
      throw AuthFailureException(_mapFailure(exception));
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
    } on AuthRemoteException catch (exception) {
      throw AuthFailureException(_mapFailure(exception));
    }
  }

  AuthFailure _mapFailure(AuthRemoteException exception) {
    if (exception.isNetworkError) {
      return NetworkAuthFailure(exception.message);
    }

    switch (exception.code) {
      case 'INVALID_CREDENTIALS':
        return const InvalidCredentialsFailure();
      case 'USER_ALREADY_EXISTS':
        return const UserAlreadyExistsFailure();
      case 'VALIDATION_ERROR':
        return ValidationAuthFailure(exception.message);
    }

    switch (exception.statusCode) {
      case 400:
        return ValidationAuthFailure(exception.message);
      case 401:
        return const InvalidCredentialsFailure();
      case 409:
        return const UserAlreadyExistsFailure();
    }

    if (exception.message.isNotEmpty) {
      return ServerAuthFailure(exception.message);
    }

    return const UnknownAuthFailure();
  }
}
