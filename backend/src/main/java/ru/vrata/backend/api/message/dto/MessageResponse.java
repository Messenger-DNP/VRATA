package ru.vrata.backend.api.message.dto;

import ru.vrata.backend.infrastructure.kafka.KafkaMessage;

public record MessageResponse(
        String id,
        Long roomId,
        Long userId,
        String username,
        String content
) {
    public static MessageResponse from(KafkaMessage message) {
        return new MessageResponse(
                message.id(),
                message.roomId(),
                message.userId(),
                message.username(),
                message.content()
        );
    }
}
