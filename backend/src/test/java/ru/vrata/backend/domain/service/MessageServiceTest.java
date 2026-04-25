package ru.vrata.backend.domain.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import ru.vrata.backend.domain.model.ChatRoom;
import ru.vrata.backend.domain.model.Message;
import ru.vrata.backend.domain.repository.ChatRoomRepository;
import ru.vrata.backend.domain.repository.RoomMessageRepository;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;
import ru.vrata.backend.infrastructure.kafka.producer.KafkaProducer;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class MessageServiceTest {

    private ChatRoomRepository chatRoomRepository;
    private RoomMessageRepository roomMessageRepository;
    private KafkaProducer kafkaProducer;
    private MessageService service;

    @BeforeEach
    void setUp() {
        chatRoomRepository = mock(ChatRoomRepository.class);
        roomMessageRepository = mock(RoomMessageRepository.class);
        kafkaProducer = mock(KafkaProducer.class);
        service = new MessageService(chatRoomRepository, roomMessageRepository, kafkaProducer);
    }

    @Test
    void sendMessageShouldSendMessage() {
        ChatRoom room = ChatRoom.create(1L, "test-room");
        when(chatRoomRepository.findById(1L)).thenReturn(Optional.of(room));
        when(chatRoomRepository.isUserInRoom(1L, 10L)).thenReturn(true);
        service.sendMessage(1L, 10L, "username", "test");
        ArgumentCaptor<KafkaMessage> captor = ArgumentCaptor.forClass(KafkaMessage.class);
        verify(kafkaProducer).produce(captor.capture());
        KafkaMessage sentMessage = captor.getValue();
        assertEquals(1L, sentMessage.roomId());
        assertEquals(10L, sentMessage.userId());
        assertEquals("username", sentMessage.username());
        assertEquals("test", sentMessage.content());
        assertNotNull(sentMessage.timestamp());
        assertNotNull(sentMessage.id());
    }

    @Test
    void sendMessageShouldThrowIfRoomNotFound() {
        when(chatRoomRepository.findById(1L)).thenReturn(Optional.empty());
        assertThrows(IllegalArgumentException.class, () -> service.sendMessage(1L, 10L, "username", "test"));
        verifyNoInteractions(kafkaProducer);
    }

    @Test
    void sendMessageShouldThrowIfUserNotInRoom() {
        ChatRoom room = ChatRoom.create(1L, "test-room");
        when(chatRoomRepository.findById(1L)).thenReturn(Optional.of(room));
        when(chatRoomRepository.isUserInRoom(1L, 10L)).thenReturn(false);
        assertThrows(IllegalArgumentException.class, () -> service.sendMessage(1L, 10L, "username", "test"));
        verifyNoInteractions(kafkaProducer);
    }

    @Test
    void getMessagesForRoomShouldReturnMessagesForRoom() {
        ChatRoom room = ChatRoom.create(1L, "test-room");
        when(chatRoomRepository.findById(1L)).thenReturn(Optional.of(room));
        Instant firstTimestamp = Instant.parse("2026-04-25T08:00:00Z");
        Instant secondTimestamp = Instant.parse("2026-04-25T08:01:00Z");
        KafkaMessage first = new KafkaMessage("id-1", 1L, 10L, "user", "hello", firstTimestamp);
        KafkaMessage second = new KafkaMessage("id-2", 2L, 10L, "user", "world", secondTimestamp);
        when(roomMessageRepository.findByRoomId(1L)).thenReturn(List.of(first, second));

        List<Message> result = service.getMessagesForRoom(1L);

        assertEquals(2, result.size());
        Message firstResult = result.get(0);
        assertEquals(1L, firstResult.roomId());
        assertEquals(10L, firstResult.userId());
        assertEquals("user", firstResult.username());
        assertEquals("hello", firstResult.content());
        assertEquals(firstTimestamp, firstResult.timestamp());
        assertNotNull(firstResult.id());
    }

    @Test
    void getMessagesForRoomShouldThrowIfRoomNotFound() {
        when(chatRoomRepository.findById(1L)).thenReturn(Optional.empty());

        assertThrows(IllegalArgumentException.class, () -> service.getMessagesForRoom(1L));
        verifyNoInteractions(roomMessageRepository);
    }

    @Test
    void getMessagesForRoomShouldThrowIfRoomIdInvalid() {
        assertThrows(IllegalArgumentException.class, () -> service.getMessagesForRoom(0L));
        verifyNoInteractions(roomMessageRepository);
    }

    @Test
    void getMessagesForRoomShouldReturnEmptyWhenNoMessagesInRoom() {
        ChatRoom room = ChatRoom.create(1L, "test-room");
        when(chatRoomRepository.findById(1L)).thenReturn(Optional.of(room));
        when(roomMessageRepository.findByRoomId(1L)).thenReturn(List.of());

        List<Message> result = service.getMessagesForRoom(1L);

        assertTrue(result.isEmpty());
    }
}
