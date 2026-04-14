enum AuthValidationError {
  emptyUsername,
  usernameTooShort,
  usernameTooLong,
  usernameInvalidCharacters,
  emptyPassword,
  passwordTooShort,
  passwordTooLong,
  passwordMissingLetter,
  passwordMissingDigit,
  passwordContainsWhitespace,
  emptyPasswordConfirmation,
  passwordMismatch,
}

abstract final class AuthFormValidator {
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 50;
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;

  static final RegExp _usernamePattern = RegExp(r'^[A-Za-z0-9_]+$');
  static final RegExp _letterPattern = RegExp(r'[A-Za-z]');
  static final RegExp _digitPattern = RegExp(r'\d');
  static final RegExp _whitespacePattern = RegExp(r'\s');

  static AuthValidationError? validateUsername(String username) {
    final normalizedUsername = username.trim();

    if (normalizedUsername.isEmpty) {
      return AuthValidationError.emptyUsername;
    }

    if (normalizedUsername.length < minUsernameLength) {
      return AuthValidationError.usernameTooShort;
    }

    if (normalizedUsername.length > maxUsernameLength) {
      return AuthValidationError.usernameTooLong;
    }

    if (!_usernamePattern.hasMatch(normalizedUsername)) {
      return AuthValidationError.usernameInvalidCharacters;
    }

    return null;
  }

  static AuthValidationError? validatePassword(String password) {
    if (password.trim().isEmpty) {
      return AuthValidationError.emptyPassword;
    }

    if (password.length < minPasswordLength) {
      return AuthValidationError.passwordTooShort;
    }

    if (password.length > maxPasswordLength) {
      return AuthValidationError.passwordTooLong;
    }

    if (_whitespacePattern.hasMatch(password)) {
      return AuthValidationError.passwordContainsWhitespace;
    }

    if (!_letterPattern.hasMatch(password)) {
      return AuthValidationError.passwordMissingLetter;
    }

    if (!_digitPattern.hasMatch(password)) {
      return AuthValidationError.passwordMissingDigit;
    }

    return null;
  }

  static AuthValidationError? validatePasswordConfirmation(
    String password,
    String confirmPassword,
  ) {
    if (confirmPassword.trim().isEmpty) {
      return AuthValidationError.emptyPasswordConfirmation;
    }

    if (password != confirmPassword) {
      return AuthValidationError.passwordMismatch;
    }

    return null;
  }
}
