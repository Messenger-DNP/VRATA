sealed class ChatLobbyFailure {
  const ChatLobbyFailure();
}

final class InvalidCredentialsChatLobbyFailure extends ChatLobbyFailure {
  const InvalidCredentialsChatLobbyFailure();
}

final class RoomNotFoundFailure extends ChatLobbyFailure {
  const RoomNotFoundFailure();
}

final class ValidationChatLobbyFailure extends ChatLobbyFailure {
  const ValidationChatLobbyFailure(this.message);

  final String message;
}

final class NetworkChatLobbyFailure extends ChatLobbyFailure {
  const NetworkChatLobbyFailure(this.message);

  final String message;
}

final class ServerChatLobbyFailure extends ChatLobbyFailure {
  const ServerChatLobbyFailure(this.message);

  final String message;
}

final class UnknownChatLobbyFailure extends ChatLobbyFailure {
  const UnknownChatLobbyFailure([
    this.message = 'Something went wrong. Please try again.',
  ]);

  final String message;
}

class ChatLobbyFailureException implements Exception {
  const ChatLobbyFailureException(this.failure);

  final ChatLobbyFailure failure;
}
