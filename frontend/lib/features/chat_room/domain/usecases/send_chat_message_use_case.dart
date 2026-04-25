import 'package:frontend/features/chat_room/domain/repositories/chat_messages_repository.dart';

class SendChatMessageUseCase {
  const SendChatMessageUseCase(this._repository);

  final ChatMessagesRepository _repository;

  Future<void> call({
    required int roomId,
    required int userId,
    required String username,
    required String content,
  }) {
    return _repository.sendMessage(
      roomId: roomId,
      userId: userId,
      username: username,
      content: content,
    );
  }
}
