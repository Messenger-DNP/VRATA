import 'package:frontend/features/chat_room/domain/entities/chat_messages_observation.dart';
import 'package:frontend/features/chat_room/domain/repositories/chat_messages_repository.dart';

class ObserveChatMessagesUseCase {
  const ObserveChatMessagesUseCase(this._repository);

  final ChatMessagesRepository _repository;

  ChatMessagesObservation call({required int roomId}) {
    return _repository.observeMessages(roomId: roomId);
  }
}
