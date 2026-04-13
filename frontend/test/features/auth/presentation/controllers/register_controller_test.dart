import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/domain/entities/auth_failure.dart';
import 'package:frontend/features/auth/domain/entities/auth_session.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/features/auth/presentation/controllers/register_controller.dart';
import 'package:frontend/features/auth/presentation/providers/auth_providers.dart';
import 'package:frontend/features/auth/presentation/state/auth_submission_status.dart';

void main() {
  group('RegisterController', () {
    test('validates password mismatch before repository call', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith(
            (ref) => FakeAuthRepository(
              onRegister: ({required username, required password}) async =>
                  sampleSession,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(registerControllerProvider.notifier);

      await controller.submit(
        username: 'alice',
        password: 'topsecret',
        confirmPassword: 'different',
      );

      final state = container.read(registerControllerProvider);
      expect(state.status, AuthSubmissionStatus.failure);
      expect(state.confirmPasswordError, 'Passwords do not match.');
      expect(state.session, isNull);
    });

    test('maps already existing user to username error', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith(
            (ref) => FakeAuthRepository(
              onRegister: ({required username, required password}) async =>
                  throw const AuthFailureException(
                UserAlreadyExistsFailure(),
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(registerControllerProvider.notifier);

      await controller.submit(
        username: 'alice',
        password: 'topsecret',
        confirmPassword: 'topsecret',
      );

      final state = container.read(registerControllerProvider);
      expect(state.status, AuthSubmissionStatus.failure);
      expect(state.usernameError, 'This username is already taken.');
      expect(state.session, isNull);
    });

    test('emits success state when registration succeeds', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith(
            (ref) => FakeAuthRepository(
              onRegister: ({required username, required password}) async =>
                  sampleSession.copyWith(username: username),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(registerControllerProvider.notifier);

      await controller.submit(
        username: 'alice',
        password: 'topsecret',
        confirmPassword: 'topsecret',
      );

      final state = container.read(registerControllerProvider);
      expect(state.status, AuthSubmissionStatus.success);
      expect(state.session?.username, 'alice');
      expect(state.usernameError, isNull);
    });
  });
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.onLogin,
    this.onRegister,
  });

  final Future<AuthSession> Function({
    required String username,
    required String password,
  })? onLogin;
  final Future<AuthSession> Function({
    required String username,
    required String password,
  })? onRegister;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) {
    return onLogin!(
      username: username,
      password: password,
    );
  }

  @override
  Future<AuthSession> register({
    required String username,
    required String password,
  }) {
    return onRegister!(
      username: username,
      password: password,
    );
  }
}

final sampleSession = AuthSession(
  userId: 1,
  username: 'sample',
  tokenType: 'Bearer',
  accessToken: 'token',
  expiresAt: DateTime.utc(2026, 1, 1),
);

extension on AuthSession {
  AuthSession copyWith({
    int? userId,
    String? username,
    String? tokenType,
    String? accessToken,
    DateTime? expiresAt,
  }) {
    return AuthSession(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      tokenType: tokenType ?? this.tokenType,
      accessToken: accessToken ?? this.accessToken,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
