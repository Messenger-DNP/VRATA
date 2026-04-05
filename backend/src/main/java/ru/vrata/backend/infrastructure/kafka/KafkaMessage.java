package ru.vrata.backend.infrastructure.kafka;

/**
 * General model for both consumer and producer
 */
public record KafkaMessage(String id, Long roomId, Long userId, String username, String content) {
}