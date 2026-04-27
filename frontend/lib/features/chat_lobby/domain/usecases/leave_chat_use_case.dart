import 'package:frontend/features/chat_lobby/domain/repositories/chat_lobby_repository.dart';

class LeaveChatUseCase {
  const LeaveChatUseCase(this._repository);

  final ChatLobbyRepository _repository;

  Future<void> call({required int userId}) {
    return _repository.leaveChat(userId: userId);
  }
}
