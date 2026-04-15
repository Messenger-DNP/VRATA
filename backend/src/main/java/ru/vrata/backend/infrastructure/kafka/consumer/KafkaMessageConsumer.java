package ru.vrata.backend.infrastructure.kafka.consumer;

import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;

/**
 * Consumes chat messages from Kafka topics that match the configured pattern.
 */
@Slf4j
@Component
public class KafkaMessageConsumer {

    /**
     * Receives a Kafka message, validates it, and prepares it for delivery.
     *
     * @param message incoming chat message
     */
    @KafkaListener(
            topicPattern = "${app.kafka.chat-topic-pattern}",
            groupId = "${spring.kafka.consumer.group-id}"
    )
    public void consume(KafkaMessage message) {
        try {
            if (!isValid(message)) {
                log.warn("Invalid Kafka message received: {}", message);
                return;
            }

            log.info(
                    "Kafka message received: id={}, roomId={}, userId={}, username={}, content={}",
                    message.id(),
                    message.roomId(),
                    message.userId(),
                    message.username(),
                    message.content()
            );
            prepareMessageDelivery(message);



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

    /**
     * Checks whether the received message contains all required fields.
     *
     * @param message Kafka message to validate
     * @return true if the message is valid, otherwise false
     */
    private boolean isValid(KafkaMessage message) {
        return message != null
                && message.id() != null
                && message.roomId() != null
                && message.userId() != null
                && message.username() != null
                && !message.username().isBlank()
                && message.content() != null
                && !message.content().isBlank();
    }

    /**
     * Prepares a valid message for delivery to room participants.
     *
     * @param message validated Kafka message
     */
    private void prepareMessageDelivery(KafkaMessage message) {
        log.info(
                "Preparing message delivery: messageId={}, roomId={}, username={}",
                message.id(),
                message.roomId(),
                message.username()
        );

        // TODO: deliver message to active users of this room
    }
}