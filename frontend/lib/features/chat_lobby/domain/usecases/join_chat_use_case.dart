import 'package:frontend/features/chat_lobby/domain/entities/chat_room.dart';
import 'package:frontend/features/chat_lobby/domain/repositories/chat_lobby_repository.dart';

class JoinChatUseCase {
  const JoinChatUseCase(this._repository);

  final ChatLobbyRepository _repository;

  Future<ChatRoom> call({
    required int userId,
    required String inviteCode,
  }) {
    return _repository.joinChat(
      userId: userId,
      inviteCode: inviteCode.trim(),
    );
  }
}
