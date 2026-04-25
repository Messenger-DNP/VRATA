package ru.vrata.backend.infrastructure.websocket;

import ru.vrata.backend.infrastructure.kafka.KafkaMessage;

import java.time.Instant;

public record LiveMessagePayload(
        String id,
        Long roomId,
        Long userId,
        String username,
        String content,
        Instant timestamp
) {
    public static LiveMessagePayload from(KafkaMessage message) {
        return new LiveMessagePayload(
                message.id(),
                message.roomId(),
                message.userId(),
                message.username(),
                message.content(),
                message.timestamp()
        );
    }
}
