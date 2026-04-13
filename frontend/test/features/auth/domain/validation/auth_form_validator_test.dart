import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/domain/validation/auth_form_validator.dart';

void main() {
  group('AuthFormValidator', () {
    test('returns errors for empty login fields', () {
      expect(
        AuthFormValidator.validateUsername('   '),
        AuthValidationError.emptyUsername,
      );
      expect(
        AuthFormValidator.validatePassword(''),
        AuthValidationError.emptyPassword,
      );
    });

    test('treats whitespace-only passwords as empty', () {
      expect(
        AuthFormValidator.validatePassword('   '),
        AuthValidationError.emptyPassword,
      );
      expect(
        AuthFormValidator.validatePasswordConfirmation('secret', '   '),
        AuthValidationError.emptyPasswordConfirmation,
      );
    });

    test('returns mismatch error for different passwords', () {
      expect(
        AuthFormValidator.validatePasswordConfirmation('secret', 'different'),
        AuthValidationError.passwordMismatch,
      );
    });

    test('returns empty confirmation error when confirm field is blank', () {
      expect(
        AuthFormValidator.validatePasswordConfirmation('secret', ''),
        AuthValidationError.emptyPasswordConfirmation,
      );
    });
  });
}
