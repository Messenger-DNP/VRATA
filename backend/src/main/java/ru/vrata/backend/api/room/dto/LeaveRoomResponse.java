package ru.vrata.backend.api.room.dto;

import ru.vrata.backend.domain.service.ChatRoomService;

public record LeaveRoomResponse(
        Long leftRoomId,
        boolean roomDeleted
) {
    public static LeaveRoomResponse from(ChatRoomService.LeaveRoomResult result) {
        return new LeaveRoomResponse(result.leftRoomId(), result.roomDeleted());
    }
}
