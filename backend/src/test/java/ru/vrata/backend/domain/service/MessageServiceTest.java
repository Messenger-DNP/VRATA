package ru.vrata.backend.domain.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import ru.vrata.backend.domain.model.ChatRoom;
import ru.vrata.backend.domain.repository.ChatRoomRepository;
import ru.vrata.backend.infrastructure.crypto.MessageCryptoService;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;
import ru.vrata.backend.infrastructure.kafka.producer.KafkaProducer;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class MessageServiceTest {
    private static final String TEST_BASE64_KEY = "MDEyMzQ1Njc4OWFiY2RlZg==";

    private ChatRoomRepository chatRoomRepository;
    private KafkaProducer kafkaProducer;
    private MessageCryptoService messageCryptoService;
    private MessageService service;

    @BeforeEach
    void setUp() {
        chatRoomRepository = mock(ChatRoomRepository.class);
        kafkaProducer = mock(KafkaProducer.class);
        messageCryptoService = new MessageCryptoService(TEST_BASE64_KEY);
        service = new MessageService(chatRoomRepository, kafkaProducer, messageCryptoService);
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
        assertNotEquals("test", sentMessage.content());
        assertTrue(sentMessage.content().startsWith("enc:v1:"));
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
}
