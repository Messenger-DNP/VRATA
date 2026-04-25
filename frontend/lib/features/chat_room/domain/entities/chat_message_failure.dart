sealed class ChatMessageFailure {
  const ChatMessageFailure();
}

final class UnauthorizedChatMessageFailure extends ChatMessageFailure {
  const UnauthorizedChatMessageFailure();
}

final class RoomNotFoundChatMessageFailure extends ChatMessageFailure {
  const RoomNotFoundChatMessageFailure();
}

final class ValidationChatMessageFailure extends ChatMessageFailure {
  const ValidationChatMessageFailure(this.message);

  final String message;
}

final class NetworkChatMessageFailure extends ChatMessageFailure {
  const NetworkChatMessageFailure(this.message);

  final String message;
}

final class ServerChatMessageFailure extends ChatMessageFailure {
  const ServerChatMessageFailure(this.message);

  final String message;
}

final class UnknownChatMessageFailure extends ChatMessageFailure {
  const UnknownChatMessageFailure([
    this.message = 'Something went wrong. Please try again.',
  ]);

  final String message;
}

class ChatMessageFailureException implements Exception {
  const ChatMessageFailureException(this.failure);

  final ChatMessageFailure failure;
}
