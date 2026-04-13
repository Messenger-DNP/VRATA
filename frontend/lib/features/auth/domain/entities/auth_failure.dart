sealed class AuthFailure {
  const AuthFailure();
}

final class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure();
}

final class UserAlreadyExistsFailure extends AuthFailure {
  const UserAlreadyExistsFailure();
}

final class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure();
}

class AuthFailureException implements Exception {
  const AuthFailureException(this.failure);

  final AuthFailure failure;
}
