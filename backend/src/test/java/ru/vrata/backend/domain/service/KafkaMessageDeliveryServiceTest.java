package ru.vrata.backend.domain.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import ru.vrata.backend.domain.model.ChatRoom;
import ru.vrata.backend.domain.repository.ChatRoomRepository;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;

import java.util.Optional;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.never;

class KafkaMessageDeliveryServiceTest {

    private ChatRoomRepository chatRoomRepository;
    private KafkaMessageDeliveryService deliveryService;

    @BeforeEach
    void setUp() {
        chatRoomRepository = Mockito.mock(ChatRoomRepository.class);
        deliveryService = new KafkaMessageDeliveryService(chatRoomRepository);
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

        assertDoesNotThrow(() -> deliveryService.deliver(message));

        verify(chatRoomRepository, times(1)).findById(1L);
        verify(chatRoomRepository, never()).findMemberIdsByRoomId(Mockito.anyLong());
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

        assertDoesNotThrow(() -> deliveryService.deliver(message));

        verify(chatRoomRepository, times(1)).findById(1L);
        verify(chatRoomRepository, times(1)).findMemberIdsByRoomId(1L);
    }

    @Test
    void deliverShouldProcessMessageWhenRoomExists() {
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

        assertDoesNotThrow(() -> deliveryService.deliver(message));

        verify(chatRoomRepository, times(1)).findById(1L);
        verify(chatRoomRepository, times(1)).findMemberIdsByRoomId(1L);
    }
}