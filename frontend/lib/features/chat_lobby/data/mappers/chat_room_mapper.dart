import 'package:frontend/features/chat_lobby/data/dto/room_response_dto.dart';
import 'package:frontend/features/chat_lobby/domain/entities/chat_room.dart';

extension ChatRoomMapper on RoomResponseDto {
  ChatRoom toDomain() {
    return ChatRoom(
      id: id,
      name: name,
      inviteCode: inviteCode,
    );
  }
}
