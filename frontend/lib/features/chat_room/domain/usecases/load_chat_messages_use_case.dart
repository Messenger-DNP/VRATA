import 'package:frontend/features/chat_room/domain/entities/chat_message.dart';
import 'package:frontend/features/chat_room/domain/repositories/chat_messages_repository.dart';

class LoadChatMessagesUseCase {
  const LoadChatMessagesUseCase(this._repository);

  final ChatMessagesRepository _repository;

  Future<List<ChatMessage>> call({
    required int roomId,
  }) {
    return _repository.loadMessages(roomId: roomId);
  }
}
