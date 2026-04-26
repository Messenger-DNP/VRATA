package ru.vrata.backend.domain.repository.inmemory;

import org.springframework.stereotype.Repository;
import ru.vrata.backend.domain.repository.RoomMessageRepository;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Repository
@ConditionalOnProperty(name = "app.repository", havingValue = "inmemory")
public class InMemoryRoomMessageRepository implements RoomMessageRepository {

    private final Map<Long, List<KafkaMessage>> messagesByRoomId = new ConcurrentHashMap<>();

    @Override
    public synchronized void saveForRoom(Long roomId, KafkaMessage message) {
        messagesByRoomId
                .computeIfAbsent(roomId, id -> new ArrayList<>())
                .add(message);
    }

    @Override
    public List<KafkaMessage> findByRoomId(Long roomId) {
        return List.copyOf(messagesByRoomId.getOrDefault(roomId, List.of()));
    }
}
