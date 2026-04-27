import 'package:frontend/features/chat_lobby/domain/entities/chat_room.dart';

abstract interface class ChatLobbyRepository {
  Future<ChatRoom> createChat({
    required int userId,
    required String name,
  });

  Future<ChatRoom> joinChat({
    required int userId,
    required String inviteCode,
  });

  Future<void> leaveChat({
    required int userId,
  });
}
