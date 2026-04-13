import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/domain/entities/auth_failure.dart';
import 'package:frontend/features/auth/domain/entities/auth_session.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/features/auth/presentation/controllers/login_controller.dart';
import 'package:frontend/features/auth/presentation/providers/auth_providers.dart';
import 'package:frontend/features/auth/presentation/state/auth_submission_status.dart';

void main() {
  group('LoginController', () {
    test('emits success state for valid credentials', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith(
            (ref) => FakeAuthRepository(
              onLogin: ({required username, required password}) async =>
                  sampleSession.copyWith(username: username),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(loginControllerProvider.notifier);

      await controller.submit(username: 'alice', password: 'topsecret');

      final state = container.read(loginControllerProvider);
      expect(state.status, AuthSubmissionStatus.success);
      expect(state.session?.username, 'alice');
      expect(state.passwordError, isNull);
    });

    test('maps invalid credentials into a field error', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith(
            (ref) => FakeAuthRepository(
              onLogin: ({required username, required password}) async =>
                  throw const AuthFailureException(
                InvalidCredentialsFailure(),
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(loginControllerProvider.notifier);

      await controller.submit(username: 'alice', password: 'wrong');

      final state = container.read(loginControllerProvider);
      expect(state.status, AuthSubmissionStatus.failure);
      expect(state.passwordError, 'Invalid username or password.');
      expect(state.session, isNull);
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
