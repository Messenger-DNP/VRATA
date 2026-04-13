import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/datasources/mock_auth_datasource.dart';
import 'package:frontend/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:frontend/features/auth/domain/entities/auth_failure.dart';

void main() {
  group('MockAuthRepository', () {
    late MockAuthRepository repository;

    setUp(() {
      repository = MockAuthRepository(
        MockAuthDatasource(latency: Duration.zero),
      );
    });

    test('registers and logs in a user successfully', () async {
      final registration = await repository.register(
        username: 'alice',
        password: 'topsecret',
      );
      final login = await repository.login(
        username: 'alice',
        password: 'topsecret',
      );

      expect(registration.username, 'alice');
      expect(login.username, 'alice');
      expect(login.userId, registration.userId);
      expect(login.tokenType, 'Bearer');
    });

    test('maps invalid credentials to a domain failure', () async {
      await repository.register(
        username: 'alice',
        password: 'topsecret',
      );

      expect(
        () => repository.login(
          username: 'alice',
          password: 'wrong-password',
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

    test('maps duplicate users to a domain failure', () async {
      await repository.register(
        username: 'alice',
        password: 'topsecret',
      );

      expect(
        () => repository.register(
          username: 'alice',
          password: 'another-secret',
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
  });
}
