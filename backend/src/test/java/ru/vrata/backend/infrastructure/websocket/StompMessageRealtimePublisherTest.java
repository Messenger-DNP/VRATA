package ru.vrata.backend.infrastructure.websocket;

import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;

import java.time.Instant;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

class StompMessageRealtimePublisherTest {

    @Test
    void publishShouldSendMessageToRoomTopic() {
        SimpMessagingTemplate messagingTemplate = mock(SimpMessagingTemplate.class);
        StompMessageRealtimePublisher publisher = new StompMessageRealtimePublisher(messagingTemplate);
        KafkaMessage message = new KafkaMessage(
                "6eaf8f46-8f17-4d24-9ec4-84768f6ab9cc",
                1L,
                42L,
                "rolan",
                "hello",
                Instant.parse("2026-04-25T08:00:00Z")
        );

        publisher.publish(message);

        ArgumentCaptor<LiveMessagePayload> payloadCaptor = ArgumentCaptor.forClass(LiveMessagePayload.class);
        verify(messagingTemplate).convertAndSend(
                eq("/topic/rooms/1/messages"),
                payloadCaptor.capture()
        );

        LiveMessagePayload payload = payloadCaptor.getValue();
        assertEquals(message.id(), payload.id());
        assertEquals(message.roomId(), payload.roomId());
        assertEquals(message.userId(), payload.userId());
        assertEquals(message.username(), payload.username());
        assertEquals(message.content(), payload.content());
        assertEquals(message.timestamp(), payload.timestamp());
    }
}
