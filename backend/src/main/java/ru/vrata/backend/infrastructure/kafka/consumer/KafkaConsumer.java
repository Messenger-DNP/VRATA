package ru.vrata.backend.infrastructure.kafka.consumer;

import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;

@Component
public class KafkaConsumer {
    // TODO (consumer): handle messages from all chat topics and filter them
    //  (like is the user present in this room)

    @KafkaListener(topics = "chat.*", groupId = "chat-group")
    public void consume(KafkaMessage message) {
        // TODO (consumer): deliver message to client, add logs
    }
}
