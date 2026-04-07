package ru.vrata.backend.infrastructure.kafka.producer;

import org.springframework.stereotype.Component;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;

@Component
public class KafkaProducer {
    // TODO (producer): send messages to topics, add logs

    public void produce(KafkaMessage message) {
        // TODO (producer): send message
    }
}
