package ru.vrata.backend.infrastructure.kafka.producer;

import org.springframework.stereotype.Component;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;

@Component
public class KafkaProducer {
    // TODO: send to topic + logs

    public void produce(KafkaMessage message) {
        // TODO: send message
    }
}
