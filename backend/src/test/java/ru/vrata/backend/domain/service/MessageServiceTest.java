package ru.vrata.backend.domain.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import ru.vrata.backend.domain.model.ChatRoom;
import ru.vrata.backend.domain.model.Message;
import ru.vrata.backend.domain.repository.ChatRoomRepository;
import ru.vrata.backend.domain.repository.DeliveredMessageRepository;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;
import ru.vrata.backend.infrastructure.kafka.producer.KafkaProducer;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class MessageServiceTest {

    private ChatRoomRepository chatRoomRepository;
    private DeliveredMessageRepository deliveredMessageRepository;
    private KafkaProducer kafkaProducer;
    private MessageService service;

    @BeforeEach
    void setUp() {
        chatRoomRepository = mock(ChatRoomRepository.class);
        deliveredMessageRepository = mock(DeliveredMessageRepository.class);
        kafkaProducer = mock(KafkaProducer.class);
        service = new MessageService(chatRoomRepository, deliveredMessageRepository, kafkaProducer);
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
    void getMessagesForRoomShouldReturnMessagesForRoomWhenUserInRoom() {
        ChatRoom room = ChatRoom.create(1L, "test-room");
        when(chatRoomRepository.findById(1L)).thenReturn(Optional.of(room));
        when(chatRoomRepository.isUserInRoom(1L, 10L)).thenReturn(true);

        KafkaMessage first = new KafkaMessage("id-1", 1L, 10L, "user", "hello");
        KafkaMessage second = new KafkaMessage("id-2", 2L, 10L, "user", "world");
        when(deliveredMessageRepository.findByRoomId(1L)).thenReturn(List.of(first, second));

        List<Message> result = service.getMessagesForRoom(1L, 10L);

        assertEquals(1, result.size());
        Message firstResult = result.get(0);
        assertEquals(1L, firstResult.roomId());
        assertEquals(10L, firstResult.userId());
        assertEquals("user", firstResult.username());
        assertEquals("hello", firstResult.content());
        assertNotNull(firstResult.id());
    }

    @Test
    void getMessagesForRoomShouldThrowIfRoomNotFound() {
        when(chatRoomRepository.findById(1L)).thenReturn(Optional.empty());

        assertThrows(IllegalArgumentException.class, () -> service.getMessagesForRoom(1L, 10L));
        verify(chatRoomRepository, never()).isUserInRoom(anyLong(), anyLong());
        verifyNoInteractions(deliveredMessageRepository);
    }

    @Test
    void getMessagesForRoomShouldThrowIfUserNotInRoom() {
        ChatRoom room = ChatRoom.create(1L, "test-room");
        when(chatRoomRepository.findById(1L)).thenReturn(Optional.of(room));
        when(chatRoomRepository.isUserInRoom(1L, 10L)).thenReturn(false);

        assertThrows(IllegalArgumentException.class, () -> service.getMessagesForRoom(1L, 10L));
        verifyNoInteractions(deliveredMessageRepository);
    }

    @Test
    void getMessagesForRoomShouldThrowIfUserIdInvalid() {
        assertThrows(IllegalArgumentException.class, () -> service.getMessagesForRoom(1L, 0L));
        verifyNoInteractions(deliveredMessageRepository);
    }

    @Test
    void getMessagesForRoomShouldThrowIfRoomIdInvalid() {
        assertThrows(IllegalArgumentException.class, () -> service.getMessagesForRoom(0L, 10L));
        verifyNoInteractions(deliveredMessageRepository);
    }

    @Test
    void getMessagesForRoomShouldReturnEmptyWhenNoMessagesInRoom() {
        ChatRoom room = ChatRoom.create(1L, "test-room");
        when(chatRoomRepository.findById(1L)).thenReturn(Optional.of(room));
        when(chatRoomRepository.isUserInRoom(1L, 10L)).thenReturn(true);

        KafkaMessage first = new KafkaMessage("id-1", 2L, 10L, "user", "hello");
        KafkaMessage second = new KafkaMessage("id-2", 3L, 10L, "user", "world");
        when(deliveredMessageRepository.findByRoomId(1L)).thenReturn(List.of(first, second));

        List<Message> result = service.getMessagesForRoom(1L, 10L);

        assertTrue(result.isEmpty());
    }
}
