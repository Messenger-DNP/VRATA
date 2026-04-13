package ru.vrata.backend.domain.service;

import org.springframework.stereotype.Service;
import ru.vrata.backend.domain.model.Message;
import ru.vrata.backend.domain.repository.ChatRoomRepository;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;
import ru.vrata.backend.infrastructure.kafka.producer.KafkaProducer;

@Service
public class MessageService {
    private final ChatRoomRepository chatRoomRepository;
    private final KafkaProducer kafkaProducer;

    public MessageService(ChatRoomRepository chatRoomRepository, KafkaProducer kafkaProducer) {
        this.chatRoomRepository = chatRoomRepository;
        this.kafkaProducer = kafkaProducer;
    }

    public void sendMessage(Long roomId, Long userId, String username, String content) {
        var room = chatRoomRepository.findById(roomId).orElseThrow(() -> new IllegalArgumentException("Room not found"));
        // TODO: check that user is in the room
        Message message = Message.create(room.id(), userId, username, content);
        KafkaMessage kafkaMessage = new KafkaMessage(
                message.id().toString(),
                message.roomId(),
                message.userId(),
                message.username(),
                message.content()
        );
        kafkaProducer.produce(kafkaMessage);
    }
}
