import 'package:frontend/features/auth/domain/entities/auth_session.dart';
import 'package:frontend/features/auth/presentation/state/auth_submission_status.dart';

const _sentinel = Object();

class LoginState {
  const LoginState({
    this.status = AuthSubmissionStatus.idle,
    this.usernameError,
    this.passwordError,
    this.session,
  });

  final AuthSubmissionStatus status;
  final String? usernameError;
  final String? passwordError;
  final AuthSession? session;

  bool get isLoading => status == AuthSubmissionStatus.loading;
  bool get isSuccess => status == AuthSubmissionStatus.success;
  bool get hasFeedback =>
      status != AuthSubmissionStatus.idle ||
      usernameError != null ||
      passwordError != null ||
      session != null;

  LoginState copyWith({
    AuthSubmissionStatus? status,
    Object? usernameError = _sentinel,
    Object? passwordError = _sentinel,
    Object? session = _sentinel,
  }) {
    return LoginState(
      status: status ?? this.status,
      usernameError: usernameError == _sentinel
          ? this.usernameError
          : usernameError as String?,
      passwordError: passwordError == _sentinel
          ? this.passwordError
          : passwordError as String?,
      session: session == _sentinel ? this.session : session as AuthSession?,
    );
  }
}
