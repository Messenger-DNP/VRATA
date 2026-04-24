package ru.vrata.backend.domain.repository.inmemory;

import org.springframework.stereotype.Repository;
import ru.vrata.backend.domain.repository.DeliveredMessageRepository;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Repository
public class InMemoryDeliveredMessageRepository implements DeliveredMessageRepository {

    private final Map<Long, List<KafkaMessage>> inboxByUserId = new ConcurrentHashMap<>();

    @Override
    public synchronized void saveForUser(Long userId, KafkaMessage message) {
        inboxByUserId
                .computeIfAbsent(userId, id -> new ArrayList<>())
                .add(message);
    }

    @Override
    public List<KafkaMessage> findByUserId(Long userId) {
        return List.copyOf(inboxByUserId.getOrDefault(userId, List.of()));
    }
}
