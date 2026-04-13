import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/domain/entities/auth_failure.dart';
import 'package:frontend/features/auth/domain/validation/auth_form_validator.dart';
import 'package:frontend/features/auth/presentation/providers/auth_providers.dart';
import 'package:frontend/features/auth/presentation/state/auth_submission_status.dart';
import 'package:frontend/features/auth/presentation/state/register_state.dart';

final registerControllerProvider =
    NotifierProvider<RegisterController, RegisterState>(
  RegisterController.new,
);

class RegisterController extends Notifier<RegisterState> {
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

      state = RegisterState(
        status: AuthSubmissionStatus.success,
        session: session,
      );
    } on AuthFailureException catch (exception) {
      state = RegisterState(
        status: AuthSubmissionStatus.failure,
        usernameError: _mapFailureMessage(exception.failure),
      );
    } catch (_) {
      state = const RegisterState(
        status: AuthSubmissionStatus.failure,
        usernameError: 'Something went wrong. Please try again.',
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
      case AuthValidationError.emptyPassword:
        return 'Please enter your password.';
      case AuthValidationError.emptyPasswordConfirmation:
        return 'Please repeat your password.';
      case AuthValidationError.passwordMismatch:
        return 'Passwords do not match.';
      case null:
        return null;
    }
  }

  String _mapFailureMessage(AuthFailure failure) {
    if (failure is UserAlreadyExistsFailure) {
      return 'This username is already taken.';
    }

    return 'Something went wrong. Please try again.';
  }
}
