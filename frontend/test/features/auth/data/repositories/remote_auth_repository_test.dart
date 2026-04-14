import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:frontend/features/auth/data/repositories/remote_auth_repository.dart';
import 'package:frontend/features/auth/domain/entities/auth_failure.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('RemoteAuthRepository', () {
    test('posts login request and maps auth response', () async {
      late Uri capturedUri;
      late String capturedBody;

      final repository = _buildRepository(
        MockClient((request) async {
          capturedUri = request.url;
          capturedBody = request.body;

          return http.Response(
            jsonEncode({
              'userId': 42,
              'username': 'rolan',
              'tokenType': 'Bearer',
              'accessToken': 'token-123',
              'expiresAt': '2026-04-13T12:00:00Z',
            }),
            200,
          );
        }),
      );

      final session = await repository.login(
        username: 'rolan',
        password: 'StrongPassword123',
      );

      expect(
        capturedUri.toString(),
        'http://localhost:8080/api/v1/auth/login',
      );
      expect(
        jsonDecode(capturedBody),
        {
          'username': 'rolan',
          'password': 'StrongPassword123',
        },
      );
      expect(session.userId, 42);
      expect(session.username, 'rolan');
      expect(session.accessToken, 'token-123');
    });

    test('maps invalid credentials from backend', () async {
      final repository = _buildRepository(
        MockClient((request) async {
          return http.Response(
            jsonEncode({
              'code': 'INVALID_CREDENTIALS',
              'message': 'Invalid username or password',
              'timestamp': '2026-04-13T12:00:00Z',
            }),
            401,
          );
        }),
      );

      expect(
        () => repository.login(
          username: 'rolan',
          password: 'WrongPassword123',
        ),
        throwsA(
          isA<AuthFailureException>().having(
            (error) => error.failure,
            'failure',
            isA<InvalidCredentialsFailure>(),
          ),
        ),
      );
    });

    test('maps duplicate user error from backend', () async {
      final repository = _buildRepository(
        MockClient((request) async {
          return http.Response(
            jsonEncode({
              'code': 'USER_ALREADY_EXISTS',
              'message': "User with username 'rolan' already exists",
              'timestamp': '2026-04-13T12:00:00Z',
            }),
            409,
          );
        }),
      );

      expect(
        () => repository.register(
          username: 'rolan',
          password: 'StrongPassword123',
        ),
        throwsA(
          isA<AuthFailureException>().having(
            (error) => error.failure,
            'failure',
            isA<UserAlreadyExistsFailure>(),
          ),
        ),
      );
    });

    test('maps backend validation errors with message', () async {
      final repository = _buildRepository(
        MockClient((request) async {
          return http.Response(
            jsonEncode({
              'code': 'VALIDATION_ERROR',
              'message': 'password length must be between 8 and 128 characters',
              'timestamp': '2026-04-13T12:00:00Z',
            }),
            400,
          );
        }),
      );

      expect(
        () => repository.login(
          username: 'rolan',
          password: 'short',
        ),
        throwsA(
          isA<AuthFailureException>().having(
            (error) => error.failure,
            'failure',
            isA<ValidationAuthFailure>().having(
              (failure) => failure.message,
              'message',
              'password length must be between 8 and 128 characters',
            ),
          ),
        ),
      );
    });

    test('maps network errors explicitly', () async {
      final repository = _buildRepository(
        MockClient((request) async {
          throw http.ClientException('Connection failed');
        }),
      );

      expect(
        () => repository.login(
          username: 'rolan',
          password: 'StrongPassword123',
        ),
        throwsA(
          isA<AuthFailureException>().having(
            (error) => error.failure,
            'failure',
            isA<NetworkAuthFailure>(),
          ),
        ),
      );
    });
  });
}

RemoteAuthRepository _buildRepository(http.Client client) {
  return RemoteAuthRepository(
    AuthRemoteDatasource(
      client: client,
      baseUrl: 'http://localhost:8080',
    ),
  );
}
