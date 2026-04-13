import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/auth_session_provider.dart';
import 'package:frontend/features/auth/auth_providers.dart';
import 'package:frontend/features/auth/domain/entities/auth_failure.dart';
import 'package:frontend/features/auth/domain/validation/auth_form_validator.dart';
import 'package:frontend/features/auth/presentation/state/auth_submission_status.dart';
import 'package:frontend/features/auth/presentation/state/register_state.dart';

final registerControllerProvider =
    AutoDisposeNotifierProvider<RegisterController, RegisterState>(
  RegisterController.new,
);

class RegisterController extends AutoDisposeNotifier<RegisterState> {
  @override
  RegisterState build() => const RegisterState();

  Future<void> submit({
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    final usernameError = _mapValidationError(
      AuthFormValidator.validateUsername(username),
    );
    final passwordError = _mapValidationError(
      AuthFormValidator.validatePassword(password),
    );
    final confirmPasswordError = _mapValidationError(
      AuthFormValidator.validatePasswordConfirmation(
        password,
        confirmPassword,
      ),
    );

    if (usernameError != null ||
        passwordError != null ||
        confirmPasswordError != null) {
      state = state.copyWith(
        status: AuthSubmissionStatus.failure,
        usernameError: usernameError,
        passwordError: passwordError,
        confirmPasswordError: confirmPasswordError,
        submissionError: null,
        session: null,
      );
      return;
    }

    state = const RegisterState(status: AuthSubmissionStatus.loading);

    try {
      final session = await ref.read(registerUseCaseProvider).call(
            username: username,
            password: password,
          );

      ref.read(authSessionProvider.notifier).setSession(session);

      state = RegisterState(
        status: AuthSubmissionStatus.success,
        session: session,
      );
    } on AuthFailureException catch (exception) {
      state = _mapFailureState(exception.failure);
    } catch (_) {
      state = const RegisterState(
        status: AuthSubmissionStatus.failure,
        submissionError: 'Something went wrong. Please try again.',
      );
    }
  }

  void onFormChanged() {
    if (!state.hasFeedback) {
      return;
    }

    state = const RegisterState();
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
      case AuthValidationError.emptyPasswordConfirmation:
        return 'Please repeat your password.';
      case AuthValidationError.passwordMismatch:
        return 'Passwords do not match.';
      case null:
        return null;
    }
  }

  RegisterState _mapFailureState(AuthFailure failure) {
    if (failure is UserAlreadyExistsFailure) {
      return const RegisterState(
        status: AuthSubmissionStatus.failure,
        usernameError: 'This username is already taken.',
      );
    }

    if (failure is ValidationAuthFailure) {
      final message = _formatMessage(failure.message);

      if (_isUsernameMessage(message)) {
        return RegisterState(
          status: AuthSubmissionStatus.failure,
          usernameError: message,
        );
      }

      if (_isPasswordMessage(message)) {
        return RegisterState(
          status: AuthSubmissionStatus.failure,
          passwordError: message,
        );
      }

      return RegisterState(
        status: AuthSubmissionStatus.failure,
        submissionError: message,
      );
    }

    if (failure is NetworkAuthFailure) {
      return RegisterState(
        status: AuthSubmissionStatus.failure,
        submissionError: failure.message,
      );
    }

    if (failure is ServerAuthFailure) {
      return RegisterState(
        status: AuthSubmissionStatus.failure,
        submissionError: failure.message,
      );
    }

    if (failure is UnknownAuthFailure) {
      return RegisterState(
        status: AuthSubmissionStatus.failure,
        submissionError: failure.message,
      );
    }

    return const RegisterState(
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
