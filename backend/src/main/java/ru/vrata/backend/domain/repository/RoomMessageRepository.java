package ru.vrata.backend.domain.repository;

import ru.vrata.backend.infrastructure.kafka.KafkaMessage;

import java.util.List;

public interface RoomMessageRepository {
    void saveForRoom(Long roomId, KafkaMessage message);

    List<KafkaMessage> findByRoomId(Long roomId);
}
