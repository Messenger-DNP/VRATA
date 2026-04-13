package ru.vrata.backend.infrastructure.kafka.producer;

import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;

@Component
public class KafkaProducer {

    private final KafkaTemplate<String, KafkaMessage> kafkaTemplate;

    public KafkaProducer(KafkaTemplate<String, KafkaMessage> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    public void produce(KafkaMessage message) {
        String topic = "chat-room-" + message.roomId();
        kafkaTemplate.send(topic, message.id(), message);
        System.out.println("Kafka producer sent message to topic=" + topic + " message=" + message);
    }
}
