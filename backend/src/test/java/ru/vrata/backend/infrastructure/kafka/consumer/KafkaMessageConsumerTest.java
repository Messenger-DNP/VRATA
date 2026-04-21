package ru.vrata.backend.infrastructure.kafka.consumer;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Mockito;
import ru.vrata.backend.domain.service.KafkaMessageDeliveryService;
import ru.vrata.backend.infrastructure.crypto.MessageCryptoService;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.mockito.Mockito.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

class KafkaMessageConsumerTest {
    private static final String TEST_BASE64_KEY = "MDEyMzQ1Njc4OWFiY2RlZg==";

    private KafkaMessageConsumer consumer;
    private KafkaMessageDeliveryService deliveryService;
    private MessageCryptoService messageCryptoService;

    @BeforeEach
    void setUp() {
        deliveryService = Mockito.mock(KafkaMessageDeliveryService.class);
        messageCryptoService = new MessageCryptoService(TEST_BASE64_KEY);
        consumer = new KafkaMessageConsumer(deliveryService, messageCryptoService);
    }

    @Test
    void consumeShouldProcessValidMessageWithoutException() {
        String encryptedContent = messageCryptoService.encrypt("hello");
        KafkaMessage message = new KafkaMessage(
                "msg-1",
                1L,
                10L,
                "riia",
                encryptedContent
        );

        assertDoesNotThrow(() -> consumer.consume(message));

        ArgumentCaptor<KafkaMessage> captor = ArgumentCaptor.forClass(KafkaMessage.class);
        verify(deliveryService, times(1)).deliver(captor.capture());
        KafkaMessage delivered = captor.getValue();
        assertEquals("msg-1", delivered.id());
        assertEquals(1L, delivered.roomId());
        assertEquals(10L, delivered.userId());
        assertEquals("riia", delivered.username());
        assertEquals("hello", delivered.content());
    }

    @Test
    void consumeShouldIgnoreNullMessageWithoutException() {
        assertDoesNotThrow(() -> consumer.consume(null));

        verify(deliveryService, never()).deliver(any());
    }

    @Test
    void consumeShouldIgnoreMessageWithNullIdWithoutException() {
        String encryptedContent = messageCryptoService.encrypt("hello");
        KafkaMessage message = new KafkaMessage(
                null,
                1L,
                10L,
                "riia",
                encryptedContent
        );

        assertDoesNotThrow(() -> consumer.consume(message));

        verify(deliveryService, never()).deliver(any());
    }

    @Test
    void consumeShouldIgnoreMessageWithBlankUsernameWithoutException() {
        String encryptedContent = messageCryptoService.encrypt("hello");
        KafkaMessage message = new KafkaMessage(
                "msg-2",
                1L,
                10L,
                "   ",
                encryptedContent
        );

        assertDoesNotThrow(() -> consumer.consume(message));

        verify(deliveryService, never()).deliver(any());
    }

    @Test
    void consumeShouldIgnoreMessageWithBlankContentWithoutException() {
        KafkaMessage message = new KafkaMessage(
                "msg-3",
                1L,
                10L,
                "riia",
                "   "
        );

        assertDoesNotThrow(() -> consumer.consume(message));

        verify(deliveryService, never()).deliver(any());
    }
}
