package ru.vrata.backend.domain.service;

import ru.vrata.backend.infrastructure.kafka.KafkaMessage;

public interface MessageRealtimePublisher {
    void publish(KafkaMessage message);
}
