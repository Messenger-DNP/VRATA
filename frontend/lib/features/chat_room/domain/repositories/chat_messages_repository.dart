import 'package:frontend/features/chat_room/domain/entities/chat_message.dart';

abstract interface class ChatMessagesRepository {
  Future<List<ChatMessage>> loadMessages({
    required int roomId,
    required int userId,
  });

  Future<void> sendMessage({
    required int roomId,
    required int userId,
    required String username,
    required String content,
  });
}
