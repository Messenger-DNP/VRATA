package ru.vrata.backend.domain.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import ru.vrata.backend.domain.repository.ChatRoomRepository;
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

    public KafkaMessageDeliveryService(ChatRoomRepository chatRoomRepository) {
        this.chatRoomRepository = chatRoomRepository;
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

        for (Long memberId : memberIds) {
            log.info(
                    "Delivery: messageId={} delivered to userId={} in roomId={}",
                    message.id(),
                    memberId,
                    message.roomId()
            );
        }

        log.info(
                "Delivery completed: messageId={}, roomId={}",
                message.id(),
                message.roomId()
        );
    }
}