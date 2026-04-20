package ru.vrata.backend.domain.repository;

import ru.vrata.backend.infrastructure.kafka.KafkaMessage;

import java.util.List;

public interface DeliveredMessageRepository {
    void saveForUser(Long userId, KafkaMessage message);

    List<KafkaMessage> findByUserId(Long userId);
}