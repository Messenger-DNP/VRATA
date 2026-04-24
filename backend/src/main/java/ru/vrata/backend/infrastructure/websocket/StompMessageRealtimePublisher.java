package ru.vrata.backend.infrastructure.websocket;

import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;
import ru.vrata.backend.domain.service.MessageRealtimePublisher;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;

@Component
public class StompMessageRealtimePublisher implements MessageRealtimePublisher {

    private static final String ROOM_MESSAGES_TOPIC_TEMPLATE = "/topic/rooms/%d/messages";

    private final SimpMessagingTemplate messagingTemplate;

    public StompMessageRealtimePublisher(SimpMessagingTemplate messagingTemplate) {
        this.messagingTemplate = messagingTemplate;
    }

    @Override
    public void publish(KafkaMessage message) {
        messagingTemplate.convertAndSend(
                ROOM_MESSAGES_TOPIC_TEMPLATE.formatted(message.roomId()),
                LiveMessagePayload.from(message)
        );
    }
}
