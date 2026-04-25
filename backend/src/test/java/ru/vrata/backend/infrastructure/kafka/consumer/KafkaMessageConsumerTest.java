package ru.vrata.backend.infrastructure.kafka.consumer;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import ru.vrata.backend.domain.service.KafkaMessageDeliveryService;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;

import java.time.Instant;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

class KafkaMessageConsumerTest {

    private KafkaMessageConsumer consumer;
    private KafkaMessageDeliveryService deliveryService;

    @BeforeEach
    void setUp() {
        deliveryService = Mockito.mock(KafkaMessageDeliveryService.class);
        consumer = new KafkaMessageConsumer(deliveryService);
    }

    @Test
    void consumeShouldProcessValidMessageWithoutException() {
        KafkaMessage message = new KafkaMessage(
                "msg-1",
                1L,
                10L,
                "riia",
                "hello",
                Instant.parse("2026-04-25T08:00:00Z")
        );

        assertDoesNotThrow(() -> consumer.consume(message));

        verify(deliveryService, times(1)).deliver(message);
    }

    @Test
    void consumeShouldIgnoreNullMessageWithoutException() {
        assertDoesNotThrow(() -> consumer.consume(null));

        verify(deliveryService, never()).deliver(Mockito.any());
    }

    @Test
    void consumeShouldIgnoreMessageWithNullIdWithoutException() {
        KafkaMessage message = new KafkaMessage(
                null,
                1L,
                10L,
                "riia",
                "hello",
                Instant.parse("2026-04-25T08:00:00Z")
        );

        assertDoesNotThrow(() -> consumer.consume(message));

        verify(deliveryService, never()).deliver(Mockito.any());
    }

    @Test
    void consumeShouldIgnoreMessageWithBlankUsernameWithoutException() {
        KafkaMessage message = new KafkaMessage(
                "msg-2",
                1L,
                10L,
                "   ",
                "hello",
                Instant.parse("2026-04-25T08:00:00Z")
        );

        assertDoesNotThrow(() -> consumer.consume(message));

        verify(deliveryService, never()).deliver(Mockito.any());
    }

    @Test
    void consumeShouldIgnoreMessageWithBlankContentWithoutException() {
        KafkaMessage message = new KafkaMessage(
                "msg-3",
                1L,
                10L,
                "riia",
                "   ",
                Instant.parse("2026-04-25T08:00:00Z")
        );

        assertDoesNotThrow(() -> consumer.consume(message));

        verify(deliveryService, never()).deliver(Mockito.any());
    }

    @Test
    void consumeShouldIgnoreMessageWithNullTimestampWithoutException() {
        KafkaMessage message = new KafkaMessage(
                "msg-4",
                1L,
                10L,
                "riia",
                "hello",
                null
        );

        assertDoesNotThrow(() -> consumer.consume(message));

        verify(deliveryService, never()).deliver(Mockito.any());
    }
}
