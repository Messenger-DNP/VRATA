package ru.vrata.backend.api.room.dto;

import ru.vrata.backend.domain.model.ChatRoom;

public record RoomResponse(
        Long id,
        String name,
        String inviteCode
) {
    public static RoomResponse from(ChatRoom chatRoom) {
        return new RoomResponse(chatRoom.id(), chatRoom.name(), chatRoom.inviteCode());
    }
}
