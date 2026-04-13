package ru.vrata.backend.infrastructure.kafka.producer;

import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;

@Component
@Slf4j
public class KafkaProducer {

    private final KafkaTemplate<String, KafkaMessage> kafkaTemplate;

    public KafkaProducer(KafkaTemplate<String, KafkaMessage> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    public void produce(KafkaMessage message) {
        String topic = "chat-room-" + message.roomId();
        kafkaTemplate.send(topic, message.id(), message);
        log.info(
                "Kafka message sent: topic={}, messageId={}, roomId={}, userId={}",
                topic,
                message.id(),
                message.roomId(),
                message.userId()
        );
    }
}
