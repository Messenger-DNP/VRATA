package ru.vrata.backend.domain.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import ru.vrata.backend.domain.model.ChatRoom;
import ru.vrata.backend.domain.repository.ChatRoomRepository;
import ru.vrata.backend.domain.repository.inmemory.InMemoryDeliveredMessageRepository;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;

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
    private InMemoryDeliveredMessageRepository deliveredMessageRepository;
    private KafkaMessageDeliveryService deliveryService;

    @BeforeEach
    void setUp() {
        chatRoomRepository = Mockito.mock(ChatRoomRepository.class);
        deliveredMessageRepository = new InMemoryDeliveredMessageRepository();
        deliveryService = new KafkaMessageDeliveryService(chatRoomRepository, deliveredMessageRepository);
    }

    @Test
    void deliverShouldReturnWhenRoomNotFound() {
        KafkaMessage message = new KafkaMessage(
                "msg-1",
                1L,
                10L,
                "riia",
                "hello"
        );

        when(chatRoomRepository.findById(1L)).thenReturn(Optional.empty());

        deliveryService.deliver(message);

        verify(chatRoomRepository, times(1)).findById(1L);
        verify(chatRoomRepository, never()).findMemberIdsByRoomId(Mockito.anyLong());

        assertTrue(deliveredMessageRepository.findByUserId(10L).isEmpty());
        assertTrue(deliveredMessageRepository.findByUserId(20L).isEmpty());
    }

    @Test
    void deliverShouldStoreMessageForEachRoomMember() {
        KafkaMessage message = new KafkaMessage(
                "msg-2",
                1L,
                10L,
                "riia",
                "hello"
        );

        ChatRoom room = new ChatRoom(1L, "test-room", "abcdef");

        when(chatRoomRepository.findById(1L)).thenReturn(Optional.of(room));
        when(chatRoomRepository.findMemberIdsByRoomId(1L)).thenReturn(Set.of(10L, 20L));

        deliveryService.deliver(message);

        verify(chatRoomRepository, times(1)).findById(1L);
        verify(chatRoomRepository, times(1)).findMemberIdsByRoomId(1L);

        assertEquals(1, deliveredMessageRepository.findByUserId(10L).size());
        assertEquals(1, deliveredMessageRepository.findByUserId(20L).size());
        assertEquals(message, deliveredMessageRepository.findByUserId(10L).get(0));
        assertEquals(message, deliveredMessageRepository.findByUserId(20L).get(0));
        assertTrue(deliveredMessageRepository.findByUserId(30L).isEmpty());
    }

    @Test
    void deliverShouldHandleEmptyRoomMembers() {
        KafkaMessage message = new KafkaMessage(
                "msg-3",
                1L,
                10L,
                "riia",
                "hello"
        );

        ChatRoom room = new ChatRoom(1L, "test-room", "abcdef");

        when(chatRoomRepository.findById(1L)).thenReturn(Optional.of(room));
        when(chatRoomRepository.findMemberIdsByRoomId(1L)).thenReturn(Set.of());

        deliveryService.deliver(message);

        verify(chatRoomRepository, times(1)).findById(1L);
        verify(chatRoomRepository, times(1)).findMemberIdsByRoomId(1L);

        assertTrue(deliveredMessageRepository.findByUserId(10L).isEmpty());
        assertTrue(deliveredMessageRepository.findByUserId(20L).isEmpty());
    }
}