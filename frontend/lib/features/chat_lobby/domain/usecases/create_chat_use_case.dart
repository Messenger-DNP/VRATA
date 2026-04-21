import 'package:frontend/features/chat_lobby/domain/entities/chat_room.dart';
import 'package:frontend/features/chat_lobby/domain/repositories/chat_lobby_repository.dart';

class CreateChatUseCase {
  const CreateChatUseCase(this._repository);

  final ChatLobbyRepository _repository;

  Future<ChatRoom> call({
    required int userId,
    required String name,
  }) {
    return _repository.createChat(
      userId: userId,
      name: name.trim(),
    );
  }
}
