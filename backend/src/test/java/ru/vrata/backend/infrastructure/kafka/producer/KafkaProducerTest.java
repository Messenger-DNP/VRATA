package ru.vrata.backend.infrastructure.kafka.producer;

import org.junit.jupiter.api.Test;
import org.springframework.kafka.core.KafkaTemplate;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;

import java.time.Instant;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

class KafkaProducerTest {
    @Test
    void produceShouldSendMessageToTopic() {
        KafkaTemplate<String, KafkaMessage> kafkaTemplate = mock(KafkaTemplate.class);
        KafkaProducer producer = new KafkaProducer(kafkaTemplate);
        KafkaMessage message = new KafkaMessage(
                "message-1",
                1L,
                10L,
                "username",
                "test",
                Instant.parse("2026-04-25T08:00:00Z")
        );
        producer.produce(message);
        verify(kafkaTemplate).send(eq("chat-room-1"), eq("message-1"), eq(message));
    }
}
