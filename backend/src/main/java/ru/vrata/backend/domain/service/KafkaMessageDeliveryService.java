package ru.vrata.backend.domain.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import ru.vrata.backend.domain.repository.ChatRoomRepository;
import ru.vrata.backend.domain.repository.RoomMessageRepository;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;

import java.util.Set;

/**
 * Handles business logic for messages received from Kafka
 * and prepares them for further delivery to room participants.
 */
@Slf4j
@Service
public class KafkaMessageDeliveryService {

    private final ChatRoomRepository chatRoomRepository;
    private final RoomMessageRepository roomMessageRepository;
    private final MessageRealtimePublisher messageRealtimePublisher;

    public KafkaMessageDeliveryService(ChatRoomRepository chatRoomRepository,
                                       RoomMessageRepository roomMessageRepository,
                                       MessageRealtimePublisher messageRealtimePublisher)
    {
        this.chatRoomRepository = chatRoomRepository;
        this.roomMessageRepository = roomMessageRepository;
        this.messageRealtimePublisher = messageRealtimePublisher;
    }

    /**
     * Processes a valid Kafka message and prepares it for delivery.
     *
     * @param message validated Kafka message
     */
    public void deliver(KafkaMessage message) {
        var roomOptional = chatRoomRepository.findById(message.roomId());

        if (roomOptional.isEmpty()) {
            log.warn(
                    "Cannot deliver Kafka message because room was not found: messageId={}, roomId={}",
                    message.id(),
                    message.roomId()
            );
            return;
        }

        Set<Long> memberIds = chatRoomRepository.findMemberIdsByRoomId(message.roomId());

        log.info(
                "Preparing delivery: messageId={}, roomId={}, recipientsCount={}",
                message.id(),
                message.roomId(),
                memberIds.size()
        );

        if (memberIds.isEmpty()) {
            log.info(
                    "Delivery skipped because room has no members: messageId={}, roomId={}",
                    message.id(),
                    message.roomId()
            );
            return;
        }

        roomMessageRepository.saveForRoom(message.roomId(), message);

        messageRealtimePublisher.publish(message);

        log.info(
                "Delivery completed: messageId={}, roomId={}",
                message.id(),
                message.roomId()
        );
    }
}
