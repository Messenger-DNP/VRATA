package ru.vrata.backend.infrastructure.kafka.contracts;

import java.time.Instant;

/**
 * Contract model for integration between auth producer and consumers.
 * Producer/consumer logic is intentionally not implemented in this task.
 */
public record AuthEvent(String eventType, Long userId, String username, Instant occurredAt) {
}
