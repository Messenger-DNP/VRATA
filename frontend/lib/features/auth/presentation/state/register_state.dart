import 'package:frontend/features/auth/domain/entities/auth_session.dart';
import 'package:frontend/features/auth/presentation/state/auth_submission_status.dart';

const _sentinel = Object();

class RegisterState {
  const RegisterState({
    this.status = AuthSubmissionStatus.idle,
    this.usernameError,
    this.passwordError,
    this.confirmPasswordError,
    this.submissionError,
    this.session,
  });

  final AuthSubmissionStatus status;
  final String? usernameError;
  final String? passwordError;
  final String? confirmPasswordError;
  final String? submissionError;
  final AuthSession? session;

  bool get isLoading => status == AuthSubmissionStatus.loading;
  bool get isSuccess => status == AuthSubmissionStatus.success;
  bool get hasFeedback =>
      status != AuthSubmissionStatus.idle ||
      usernameError != null ||
      passwordError != null ||
      confirmPasswordError != null ||
      submissionError != null ||
      session != null;

  RegisterState copyWith({
    AuthSubmissionStatus? status,
    Object? usernameError = _sentinel,
    Object? passwordError = _sentinel,
    Object? confirmPasswordError = _sentinel,
    Object? submissionError = _sentinel,
    Object? session = _sentinel,
  }) {
    return RegisterState(
      status: status ?? this.status,
      usernameError: usernameError == _sentinel
          ? this.usernameError
          : usernameError as String?,
      passwordError: passwordError == _sentinel
          ? this.passwordError
          : passwordError as String?,
      confirmPasswordError: confirmPasswordError == _sentinel
          ? this.confirmPasswordError
          : confirmPasswordError as String?,
      submissionError: submissionError == _sentinel
          ? this.submissionError
          : submissionError as String?,
      session: session == _sentinel ? this.session : session as AuthSession?,
    );
  }
}
