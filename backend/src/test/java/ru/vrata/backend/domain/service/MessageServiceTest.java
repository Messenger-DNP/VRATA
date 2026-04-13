package ru.vrata.backend.domain.service;

import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import ru.vrata.backend.domain.model.ChatRoom;
import ru.vrata.backend.domain.repository.ChatRoomRepository;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;
import ru.vrata.backend.infrastructure.kafka.producer.KafkaProducer;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class MessageServiceTest {
    @Test
    void sendMessageShouldSendMessage() {
        ChatRoomRepository chatRoomRepository = mock(ChatRoomRepository.class);
        KafkaProducer kafkaProducer = mock(KafkaProducer.class);
        MessageService service = new MessageService(chatRoomRepository, kafkaProducer);
        ChatRoom room = ChatRoom.create(1L, "test-room");
        when(chatRoomRepository.findById(1L)).thenReturn(Optional.of(room));
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
        ChatRoomRepository chatRoomRepository = mock(ChatRoomRepository.class);
        KafkaProducer kafkaProducer = mock(KafkaProducer.class);
        MessageService service = new MessageService(chatRoomRepository, kafkaProducer);
        when(chatRoomRepository.findById(1L)).thenReturn(Optional.empty());
        assertThrows(IllegalArgumentException.class, () -> service.sendMessage(1L, 10L, "username", "test"));
        verifyNoInteractions(kafkaProducer);
    }
}