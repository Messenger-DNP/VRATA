sealed class AuthFailure {
  const AuthFailure();
}

final class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure();
}

final class UserAlreadyExistsFailure extends AuthFailure {
  const UserAlreadyExistsFailure();
}

final class ValidationAuthFailure extends AuthFailure {
  const ValidationAuthFailure(this.message);

  final String message;
}

final class NetworkAuthFailure extends AuthFailure {
  const NetworkAuthFailure(this.message);

  final String message;
}

final class ServerAuthFailure extends AuthFailure {
  const ServerAuthFailure(this.message);

  final String message;
}

final class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure([
    this.message = 'Something went wrong. Please try again.',
  ]);

  final String message;
}

class AuthFailureException implements Exception {
  const AuthFailureException(this.failure);

  final AuthFailure failure;
}
