import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/chat_lobby/domain/validation/chat_lobby_form_validator.dart';

void main() {
  group('ChatLobbyFormValidator', () {
    test('validates chat names', () {
      expect(
        ChatLobbyFormValidator.validateChatName(''),
        ChatLobbyValidationError.emptyChatName,
      );
      expect(
        ChatLobbyFormValidator.validateChatName('ab'),
        ChatLobbyValidationError.chatNameTooShort,
      );
      expect(
        ChatLobbyFormValidator.validateChatName('a' * 101),
        ChatLobbyValidationError.chatNameTooLong,
      );
      expect(ChatLobbyFormValidator.validateChatName('Project Mars'), isNull);
    });

    test('validates invite codes', () {
      expect(
        ChatLobbyFormValidator.validateInviteCode(''),
        ChatLobbyValidationError.emptyInviteCode,
      );
      expect(
        ChatLobbyFormValidator.validateInviteCode('abc12x'),
        ChatLobbyValidationError.inviteCodeInvalid,
      );
      expect(
        ChatLobbyFormValidator.validateInviteCode('abcdefg'),
        ChatLobbyValidationError.inviteCodeInvalid,
      );
      expect(ChatLobbyFormValidator.validateInviteCode('AbCdEf'), isNull);
    });
  });
}
