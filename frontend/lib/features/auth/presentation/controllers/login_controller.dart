import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/auth_session_provider.dart';
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
        submissionError: null,
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

      ref.read(authSessionProvider.notifier).setSession(session);

      state = LoginState(
        status: AuthSubmissionStatus.success,
        session: session,
      );
    } on AuthFailureException catch (exception) {
      state = _mapFailureState(exception.failure);
    } catch (_) {
      state = const LoginState(
        status: AuthSubmissionStatus.failure,
        submissionError: 'Something went wrong. Please try again.',
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
      case AuthValidationError.usernameTooShort:
        return 'Username must be at least 3 characters.';
      case AuthValidationError.usernameTooLong:
        return 'Username must be 50 characters or fewer.';
      case AuthValidationError.usernameInvalidCharacters:
        return 'Use only letters, numbers, and underscores.';
      case AuthValidationError.emptyPassword:
        return 'Please enter your password.';
      case AuthValidationError.passwordTooShort:
        return 'Password must be at least 8 characters.';
      case AuthValidationError.passwordTooLong:
        return 'Password must be 128 characters or fewer.';
      case AuthValidationError.passwordMissingLetter:
        return 'Password must include at least one letter.';
      case AuthValidationError.passwordMissingDigit:
        return 'Password must include at least one number.';
      case AuthValidationError.passwordContainsWhitespace:
        return 'Password cannot contain spaces.';
      case null:
      case AuthValidationError.emptyPasswordConfirmation:
      case AuthValidationError.passwordMismatch:
        return null;
    }
  }

  LoginState _mapFailureState(AuthFailure failure) {
    if (failure is InvalidCredentialsFailure) {
      return const LoginState(
        status: AuthSubmissionStatus.failure,
        passwordError: 'Invalid username or password.',
      );
    }

    if (failure is ValidationAuthFailure) {
      final message = _formatMessage(failure.message);

      if (_isUsernameMessage(message)) {
        return LoginState(
          status: AuthSubmissionStatus.failure,
          usernameError: message,
        );
      }

      if (_isPasswordMessage(message)) {
        return LoginState(
          status: AuthSubmissionStatus.failure,
          passwordError: message,
        );
      }

      return LoginState(
        status: AuthSubmissionStatus.failure,
        submissionError: message,
      );
    }

    if (failure is NetworkAuthFailure) {
      return LoginState(
        status: AuthSubmissionStatus.failure,
        submissionError: failure.message,
      );
    }

    if (failure is ServerAuthFailure) {
      return LoginState(
        status: AuthSubmissionStatus.failure,
        submissionError: failure.message,
      );
    }

    if (failure is UnknownAuthFailure) {
      return LoginState(
        status: AuthSubmissionStatus.failure,
        submissionError: failure.message,
      );
    }

    return const LoginState(
      status: AuthSubmissionStatus.failure,
      submissionError: 'Something went wrong. Please try again.',
    );
  }

  String _formatMessage(String message) {
    if (message.isEmpty) {
      return 'Something went wrong. Please try again.';
    }

    final normalized = '${message[0].toUpperCase()}${message.substring(1)}';

    if (normalized.endsWith('.')) {
      return normalized;
    }

    return '$normalized.';
  }

  bool _isUsernameMessage(String message) {
    return message.toLowerCase().contains('username');
  }

  bool _isPasswordMessage(String message) {
    return message.toLowerCase().contains('password');
  }
}
