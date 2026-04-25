import 'package:frontend/features/chat_room/domain/entities/chat_message.dart';
import 'package:frontend/features/chat_room/domain/entities/chat_messages_observation.dart';

abstract interface class ChatMessagesRepository {
  Future<List<ChatMessage>> loadMessages({
    required int roomId,
    required int userId,
  });

  ChatMessagesObservation observeMessages({
    required int roomId,
  });

  Future<void> sendMessage({
    required int roomId,
    required int userId,
    required String username,
    required String content,
  });
}
