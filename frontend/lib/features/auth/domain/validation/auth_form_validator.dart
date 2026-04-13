enum AuthValidationError {
  emptyUsername,
  emptyPassword,
  emptyPasswordConfirmation,
  passwordMismatch,
}

abstract final class AuthFormValidator {
  static AuthValidationError? validateUsername(String username) {
    if (username.trim().isEmpty) {
      return AuthValidationError.emptyUsername;
    }

    return null;
  }

  static AuthValidationError? validatePassword(String password) {
    if (password.isEmpty) {
      return AuthValidationError.emptyPassword;
    }

    return null;
  }

  static AuthValidationError? validatePasswordConfirmation(
    String password,
    String confirmPassword,
  ) {
    if (confirmPassword.isEmpty) {
      return AuthValidationError.emptyPasswordConfirmation;
    }

    if (password != confirmPassword) {
      return AuthValidationError.passwordMismatch;
    }

    return null;
  }
}
