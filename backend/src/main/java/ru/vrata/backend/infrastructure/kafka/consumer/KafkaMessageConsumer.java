package ru.vrata.backend.infrastructure.kafka.consumer;

import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;

@Slf4j
@Component
public class KafkaMessageConsumer {
    /**
     * Listens to all chat topics.
     * Example topics:
     * - chat-room-1
     * - chat-room-2
     * - chat-room-15
     *
     * topicPattern means:
     * listen to every Kafka topic whose name matches this regex.
     */
    @KafkaListener(topicPattern = "chat-room-.*",)
    public void consume(KafkaMessage message) {
        try {
            log.info(
                    "Kafka message received: id={}, roomId={}, userId={}, username={}, content={}",
                    message.id(),
                    message.roomId(),
                    message.userId(),
                    message.username(),
                    message.content()
            );

            /*
             *  Implement message delivery here
             */

            log.info(
                    "Message is prepared for further delivery to users in room {}",
                    message.roomId()
            );
        } catch (Exception e) {
            log.error(
                    "Error while processing Kafka message with id={}",
                    message != null ? message.id() : null,
                    e
            );
        }

    }
}