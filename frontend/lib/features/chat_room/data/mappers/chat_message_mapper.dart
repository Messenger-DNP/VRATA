import 'package:frontend/features/chat_room/data/dto/message_response_dto.dart';
import 'package:frontend/features/chat_room/domain/entities/chat_message.dart';

extension MessageResponseDtoMapper on MessageResponseDto {
  ChatMessage toDomain() {
    return ChatMessage(
      id: id,
      roomId: roomId,
      userId: userId,
      username: username,
      content: content,
    );
  }
}
