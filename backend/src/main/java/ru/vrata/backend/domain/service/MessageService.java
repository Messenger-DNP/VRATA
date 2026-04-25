package ru.vrata.backend.domain.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import ru.vrata.backend.domain.model.Message;
import ru.vrata.backend.domain.repository.ChatRoomRepository;
import ru.vrata.backend.domain.repository.RoomMessageRepository;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;
import ru.vrata.backend.infrastructure.kafka.producer.KafkaProducer;

import java.util.List;

@Service
@Slf4j
public class MessageService {
    private final ChatRoomRepository chatRoomRepository;
    private final RoomMessageRepository roomMessageRepository;
    private final KafkaProducer kafkaProducer;

    public MessageService(ChatRoomRepository chatRoomRepository,
                          RoomMessageRepository roomMessageRepository,
                          KafkaProducer kafkaProducer)
    {
        this.chatRoomRepository = chatRoomRepository;
        this.roomMessageRepository = roomMessageRepository;
        this.kafkaProducer = kafkaProducer;
    }

    public void sendMessage(Long roomId, Long userId, String username, String content) {
        var room = chatRoomRepository.findById(roomId).orElseThrow(() -> new IllegalArgumentException("Room not found"));
        if (!chatRoomRepository.isUserInRoom(roomId, userId)) {
            throw new IllegalArgumentException("User is not in the room");
        }
        Message message = Message.create(room.id(), userId, username, content);
        log.info(
                "Creating message: messageId={}, roomId={}, userId={}, username={}",
                message.id(),
                message.roomId(),
                message.userId(),
                message.username()
        );
        KafkaMessage kafkaMessage = new KafkaMessage(
                message.id().toString(),
                message.roomId(),
                message.userId(),
                message.username(),
                message.content(),
                message.timestamp()
        );
        kafkaProducer.produce(kafkaMessage);
    }

    public List<Message> getMessagesForRoom(Long roomId) {
        validateRoomId(roomId);

        chatRoomRepository.findById(roomId)
                .orElseThrow(() -> new IllegalArgumentException("Room not found"));

        return roomMessageRepository.findByRoomId(roomId).stream()
                .map(Message::from)
                .sorted((left, right) -> left.timestamp().compareTo(right.timestamp()))
                .toList();
    }

    private void validateRoomId(Long roomId) {
        if (roomId == null || roomId <= 0) {
            throw new IllegalArgumentException("room id must be positive");
        }
    }
}
