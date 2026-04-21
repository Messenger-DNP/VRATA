enum ChatLobbyValidationError {
  emptyChatName,
  chatNameTooShort,
  chatNameTooLong,
  emptyInviteCode,
  inviteCodeInvalid,
}

abstract final class ChatLobbyFormValidator {
  static const int minChatNameLength = 3;
  static const int maxChatNameLength = 100;

  static final RegExp _inviteCodePattern = RegExp(r'^[A-Za-z]{6}$');

  static ChatLobbyValidationError? validateChatName(String name) {
    final normalizedName = name.trim();

    if (normalizedName.isEmpty) {
      return ChatLobbyValidationError.emptyChatName;
    }

    if (normalizedName.length < minChatNameLength) {
      return ChatLobbyValidationError.chatNameTooShort;
    }

    if (normalizedName.length > maxChatNameLength) {
      return ChatLobbyValidationError.chatNameTooLong;
    }

    return null;
  }

  static ChatLobbyValidationError? validateInviteCode(String inviteCode) {
    final normalizedInviteCode = inviteCode.trim();

    if (normalizedInviteCode.isEmpty) {
      return ChatLobbyValidationError.emptyInviteCode;
    }

    if (!_inviteCodePattern.hasMatch(normalizedInviteCode)) {
      return ChatLobbyValidationError.inviteCodeInvalid;
    }

    return null;
  }
}
