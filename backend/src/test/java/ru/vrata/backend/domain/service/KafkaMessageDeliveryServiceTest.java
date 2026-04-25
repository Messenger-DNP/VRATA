package ru.vrata.backend.domain.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import ru.vrata.backend.domain.model.ChatRoom;
import ru.vrata.backend.domain.repository.ChatRoomRepository;
import ru.vrata.backend.domain.repository.inmemory.InMemoryRoomMessageRepository;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;

import java.time.Instant;
import java.util.Optional;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class KafkaMessageDeliveryServiceTest {

    private ChatRoomRepository chatRoomRepository;
    private InMemoryRoomMessageRepository roomMessageRepository;
    private MessageRealtimePublisher messageRealtimePublisher;
    private KafkaMessageDeliveryService deliveryService;

    @BeforeEach
    void setUp() {
        chatRoomRepository = Mockito.mock(ChatRoomRepository.class);
        roomMessageRepository = new InMemoryRoomMessageRepository();
        messageRealtimePublisher = Mockito.mock(MessageRealtimePublisher.class);
        deliveryService = new KafkaMessageDeliveryService(
                chatRoomRepository,
                roomMessageRepository,
                messageRealtimePublisher
        );
    }

    @Test
    void deliverShouldReturnWhenRoomNotFound() {
        KafkaMessage message = new KafkaMessage(
                "msg-1",
                1L,
                10L,
                "riia",
                "hello",
                Instant.parse("2026-04-25T08:00:00Z")
        );

        when(chatRoomRepository.findById(1L)).thenReturn(Optional.empty());

        deliveryService.deliver(message);

        verify(chatRoomRepository, times(1)).findById(1L);
        verify(chatRoomRepository, never()).findMemberIdsByRoomId(Mockito.anyLong());
        verify(messageRealtimePublisher, never()).publish(Mockito.any());

        assertTrue(roomMessageRepository.findByRoomId(1L).isEmpty());
    }

    @Test
    void deliverShouldStoreMessageForEachRoomMember() {
        KafkaMessage message = new KafkaMessage(
                "msg-2",
                1L,
                10L,
                "riia",
                "hello",
                Instant.parse("2026-04-25T08:00:00Z")
        );

        ChatRoom room = new ChatRoom(1L, "test-room", "abcdef");

        when(chatRoomRepository.findById(1L)).thenReturn(Optional.of(room));
        when(chatRoomRepository.findMemberIdsByRoomId(1L)).thenReturn(Set.of(10L, 20L));

        deliveryService.deliver(message);

        verify(chatRoomRepository, times(1)).findById(1L);
        verify(chatRoomRepository, times(1)).findMemberIdsByRoomId(1L);

        assertEquals(1, roomMessageRepository.findByRoomId(1L).size());
        assertEquals(message, roomMessageRepository.findByRoomId(1L).get(0));
        verify(messageRealtimePublisher, times(1)).publish(message);
    }

    @Test
    void deliverShouldHandleEmptyRoomMembers() {
        KafkaMessage message = new KafkaMessage(
                "msg-3",
                1L,
                10L,
                "riia",
                "hello",
                Instant.parse("2026-04-25T08:00:00Z")
        );

        ChatRoom room = new ChatRoom(1L, "test-room", "abcdef");

        when(chatRoomRepository.findById(1L)).thenReturn(Optional.of(room));
        when(chatRoomRepository.findMemberIdsByRoomId(1L)).thenReturn(Set.of());

        deliveryService.deliver(message);

        verify(chatRoomRepository, times(1)).findById(1L);
        verify(chatRoomRepository, times(1)).findMemberIdsByRoomId(1L);

        assertTrue(roomMessageRepository.findByRoomId(1L).isEmpty());
        verify(messageRealtimePublisher, never()).publish(Mockito.any());
    }
}
