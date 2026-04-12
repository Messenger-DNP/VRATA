package ru.vrata.backend.infrastructure.kafka.consumer;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;
import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;


class KafkaMessageConsumerTest {

    private KafkaMessageConsumer consumer;

    @BeforeEach
    void setUp() {
        consumer = new KafkaMessageConsumer();
    }

    @Test
    void consumeShouldProcessValidMessageWithoutException() {
        KafkaMessage message = new KafkaMessage(
                "msg-1",
                1L,
                10L,
                "vika",
                "hello"
        );

        assertDoesNotThrow(() -> consumer.consume(message));
    }

    @Test
    void consumeShouldIgnoreNullMessageWithoutException() {
        assertDoesNotThrow(() -> consumer.consume(null));
    }

    @Test
    void consumeShouldIgnoreMessageWithNullIdWithoutException() {
        KafkaMessage message = new KafkaMessage(
                null,
                1L,
                10L,
                "vika",
                "hello"
        );

        assertDoesNotThrow(() -> consumer.consume(message));
    }

    @Test
    void consumeShouldIgnoreMessageWithBlankUsernameWithoutException() {
        KafkaMessage message = new KafkaMessage(
                "msg-2",
                1L,
                10L,
                "   ",
                "hello"
        );

        assertDoesNotThrow(() -> consumer.consume(message));
    }

    @Test
    void consumeShouldIgnoreMessageWithBlankContentWithoutException() {
        KafkaMessage message = new KafkaMessage(
                "msg-3",
                1L,
                10L,
                "vika",
                "   "
        );

        assertDoesNotThrow(() -> consumer.consume(message));
    }
}