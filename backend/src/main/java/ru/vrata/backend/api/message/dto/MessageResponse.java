package ru.vrata.backend.api.message.dto;

import ru.vrata.backend.domain.model.Message;

import java.time.Instant;
import java.util.UUID;

public record MessageResponse(
        UUID id,
        Long roomId,
        Long userId,
        String username,
        String content,
        Instant timestamp
) {
    public static MessageResponse from(Message message) {
        return new MessageResponse(
                message.id(),
                message.roomId(),
                message.userId(),
                message.username(),
                message.content(),
                message.timestamp()
        );
    }
}
