package ru.vrata.backend.infrastructure.websocket;

import ru.vrata.backend.infrastructure.kafka.KafkaMessage;

public record LiveMessagePayload(
        String id,
        Long roomId,
        Long userId,
        String username,
        String content
) {
    public static LiveMessagePayload from(KafkaMessage message) {
        return new LiveMessagePayload(
                message.id(),
                message.roomId(),
                message.userId(),
                message.username(),
                message.content()
        );
    }
}
