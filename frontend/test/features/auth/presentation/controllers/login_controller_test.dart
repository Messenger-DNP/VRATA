import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/auth_session_provider.dart';
import 'package:frontend/features/auth/auth_providers.dart';
import 'package:frontend/features/auth/domain/entities/auth_failure.dart';
import 'package:frontend/features/auth/domain/entities/auth_session.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/features/auth/presentation/controllers/login_controller.dart';
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
      final subscription = container.listen(
        loginControllerProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);

      final controller = container.read(loginControllerProvider.notifier);

      await controller.submit(username: 'alice', password: 'topsecret1');

      final state = subscription.read();
      expect(state.status, AuthSubmissionStatus.success);
      expect(state.session?.username, 'alice');
      expect(state.passwordError, isNull);
      expect(container.read(authSessionProvider)?.username, 'alice');
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
      final subscription = container.listen(
        loginControllerProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);

      final controller = container.read(loginControllerProvider.notifier);

      await controller.submit(username: 'alice', password: 'wrongpass1');

      final state = subscription.read();
      expect(state.status, AuthSubmissionStatus.failure);
      expect(state.passwordError, 'Invalid username or password.');
      expect(state.session, isNull);
      expect(container.read(authSessionProvider), isNull);
    });

    test('returns specific feedback for invalid username and password',
        () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith(
            (ref) => FakeAuthRepository(
              onLogin: ({required username, required password}) async =>
                  sampleSession,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        loginControllerProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);

      final controller = container.read(loginControllerProvider.notifier);

      await controller.submit(username: 'alice!', password: 'password');

      final state = subscription.read();
      expect(state.status, AuthSubmissionStatus.failure);
      expect(
          state.usernameError, 'Use only letters, numbers, and underscores.');
      expect(state.passwordError, 'Password must include at least one number.');
    });

    test('emits loading state while login request is in flight', () async {
      final completer = Completer<AuthSession>();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith(
            (ref) => FakeAuthRepository(
              onLogin: ({required username, required password}) =>
                  completer.future,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        loginControllerProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);

      final controller = container.read(loginControllerProvider.notifier);
      final future =
          controller.submit(username: 'alice', password: 'topsecret1');

      expect(subscription.read().status, AuthSubmissionStatus.loading);

      completer.complete(sampleSession.copyWith(username: 'alice'));
      await future;

      expect(subscription.read().status, AuthSubmissionStatus.success);
      expect(container.read(authSessionProvider)?.username, 'alice');
    });

    test('maps network failures to submission feedback', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith(
            (ref) => FakeAuthRepository(
              onLogin: ({required username, required password}) async =>
                  throw const AuthFailureException(
                NetworkAuthFailure('Could not connect to the server.'),
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        loginControllerProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);

      final controller = container.read(loginControllerProvider.notifier);

      await controller.submit(username: 'alice', password: 'topsecret1');

      final state = subscription.read();
      expect(state.status, AuthSubmissionStatus.failure);
      expect(state.submissionError, 'Could not connect to the server.');
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
