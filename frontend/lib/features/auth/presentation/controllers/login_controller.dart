import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/auth_providers.dart';
import 'package:frontend/features/auth/domain/entities/auth_failure.dart';
import 'package:frontend/features/auth/domain/validation/auth_form_validator.dart';
import 'package:frontend/features/auth/presentation/state/auth_submission_status.dart';
import 'package:frontend/features/auth/presentation/state/login_state.dart';

final loginControllerProvider =
    AutoDisposeNotifierProvider<LoginController, LoginState>(
  LoginController.new,
);

class LoginController extends AutoDisposeNotifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  Future<void> submit({
    required String username,
    required String password,
  }) async {
    final usernameError = _mapValidationError(
      AuthFormValidator.validateUsername(username),
    );
    final passwordError = _mapValidationError(
      AuthFormValidator.validatePassword(password),
    );

    if (usernameError != null || passwordError != null) {
      state = state.copyWith(
        status: AuthSubmissionStatus.failure,
        usernameError: usernameError,
        passwordError: passwordError,
        session: null,
      );
      return;
    }

    state = const LoginState(status: AuthSubmissionStatus.loading);

    try {
      final session = await ref.read(loginUseCaseProvider).call(
            username: username,
            password: password,
          );

      state = LoginState(
        status: AuthSubmissionStatus.success,
        session: session,
      );
    } on AuthFailureException catch (exception) {
      state = LoginState(
        status: AuthSubmissionStatus.failure,
        passwordError: _mapFailureMessage(exception.failure),
      );
    } catch (_) {
      state = const LoginState(
        status: AuthSubmissionStatus.failure,
        passwordError: 'Something went wrong. Please try again.',
      );
    }
  }

  void onFormChanged() {
    if (!state.hasFeedback) {
      return;
    }

    state = const LoginState();
  }

  String? _mapValidationError(AuthValidationError? error) {
    switch (error) {
      case AuthValidationError.emptyUsername:
        return 'Please enter your username.';
      case AuthValidationError.emptyPassword:
        return 'Please enter your password.';
      case null:
      case AuthValidationError.emptyPasswordConfirmation:
      case AuthValidationError.passwordMismatch:
        return null;
    }
  }

  String _mapFailureMessage(AuthFailure failure) {
    if (failure is InvalidCredentialsFailure) {
      return 'Invalid username or password.';
    }

    return 'Something went wrong. Please try again.';
  }
}
