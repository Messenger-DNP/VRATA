package ru.vrata.backend.domain.repository.inmemory;

import org.junit.jupiter.api.Test;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;

import java.time.Instant;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

class InMemoryDeliveredMessageRepositoryTest {

    @Test
    void findByRoomIdShouldReturnRoomMessagesWithoutDuplicates() {
        InMemoryDeliveredMessageRepository repository = new InMemoryDeliveredMessageRepository();
        KafkaMessage roomOne = new KafkaMessage(
                "msg-1",
                1L,
                10L,
                "alice",
                "hello",
                Instant.parse("2026-04-25T08:00:00Z")
        );
        KafkaMessage roomTwo = new KafkaMessage(
                "msg-2",
                2L,
                10L,
                "alice",
                "other room",
                Instant.parse("2026-04-25T08:01:00Z")
        );

        repository.saveForUser(10L, roomOne);
        repository.saveForUser(10L, roomTwo);
        repository.saveForUser(20L, roomOne);

        List<KafkaMessage> found = repository.findByRoomId(1L);

        assertEquals(1, found.size());
        assertEquals("msg-1", found.get(0).id());
        assertEquals(1L, found.get(0).roomId());
    }
}
