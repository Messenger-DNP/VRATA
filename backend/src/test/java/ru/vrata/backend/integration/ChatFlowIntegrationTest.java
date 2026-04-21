package ru.vrata.backend.integration;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;
import ru.vrata.backend.domain.model.ChatRoom;
import ru.vrata.backend.domain.repository.ChatRoomRepository;
import ru.vrata.backend.domain.repository.DeliveredMessageRepository;
import ru.vrata.backend.domain.service.ChatRoomService;
import ru.vrata.backend.domain.service.MessageService;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;
import ru.vrata.backend.infrastructure.kafka.consumer.KafkaMessageConsumer;
import ru.vrata.backend.infrastructure.kafka.producer.KafkaProducer;

import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

@SpringBootTest(properties = {
        "app.message.encryption.key=MDEyMzQ1Njc4OWFiY2RlZg==",
        "app.kafka.chat-topic-pattern=^chat-room-[0-9]+$",
        "spring.kafka.listener.auto-startup=false"
})
@Import(ChatFlowIntegrationTest.TestKafkaProducerConfig.class)
class ChatFlowIntegrationTest {

    private static final long ROOM_TEST_CREATOR_ID = 20_001L;
    private static final long ROOM_TEST_MEMBER_ID = 20_002L;
    private static final long MESSAGE_TEST_CREATOR_ID = 30_001L;
    private static final long MESSAGE_TEST_MEMBER_ID = 30_002L;
    private static final String CREATOR_USERNAME = "creator_user";
    private static final String MESSAGE_CONTENT = "hello integration flow";

    @Autowired
    private ChatRoomService chatRoomService;

    @Autowired
    private MessageService messageService;

    @Autowired
    private ChatRoomRepository chatRoomRepository;

    @Autowired
    private DeliveredMessageRepository deliveredMessageRepository;

    @Autowired
    private KafkaMessageConsumer kafkaMessageConsumer;

    @Autowired
    private CapturingKafkaProducer kafkaProducer;

    @BeforeEach
    void setUp() {
        kafkaProducer.clear();
    }

    @Test
    void createAndJoinRoomShouldPlaceUsersIntoSameRoom() {
        ChatRoom room = chatRoomService.createRoom(ROOM_TEST_CREATOR_ID, "Integration room");
        ChatRoom joined = chatRoomService.joinRoom(ROOM_TEST_MEMBER_ID, room.inviteCode().toUpperCase());

        assertEquals(room.id(), joined.id());
        assertTrue(chatRoomRepository.isUserInRoom(room.id(), ROOM_TEST_CREATOR_ID));
        assertTrue(chatRoomRepository.isUserInRoom(room.id(), ROOM_TEST_MEMBER_ID));
    }

    @Test
    void sendMessageShouldEncryptForKafkaAndDeliverDecryptedToAllRoomMembers() {
        ChatRoom room = chatRoomService.createRoom(MESSAGE_TEST_CREATOR_ID, "Encrypted delivery room");
        chatRoomService.joinRoom(MESSAGE_TEST_MEMBER_ID, room.inviteCode());

        messageService.sendMessage(room.id(), MESSAGE_TEST_CREATOR_ID, CREATOR_USERNAME, MESSAGE_CONTENT);

        KafkaMessage produced = kafkaProducer.singleProducedMessage();
        assertTrue(produced.content().startsWith("enc:v1:"));
        assertNotEquals(MESSAGE_CONTENT, produced.content());

        kafkaMessageConsumer.consume(produced);

        List<KafkaMessage> creatorInbox = deliveredMessageRepository.findByUserId(MESSAGE_TEST_CREATOR_ID);
        List<KafkaMessage> memberInbox = deliveredMessageRepository.findByUserId(MESSAGE_TEST_MEMBER_ID);

        assertEquals(1, creatorInbox.size());
        assertEquals(1, memberInbox.size());
        assertEquals(MESSAGE_CONTENT, creatorInbox.get(0).content());
        assertEquals(MESSAGE_CONTENT, memberInbox.get(0).content());
    }

    @TestConfiguration
    static class TestKafkaProducerConfig {
        @Bean
        @Primary
        CapturingKafkaProducer capturingKafkaProducer() {
            return new CapturingKafkaProducer();
        }
    }

    static final class CapturingKafkaProducer extends KafkaProducer {
        private final List<KafkaMessage> producedMessages = new CopyOnWriteArrayList<>();

        CapturingKafkaProducer() {
            super(null);
        }

        @Override
        public void produce(KafkaMessage message) {
            producedMessages.add(message);
        }

        KafkaMessage singleProducedMessage() {
            assertEquals(1, producedMessages.size(), "Expected exactly one produced Kafka message");
            return producedMessages.get(0);
        }

        void clear() {
            producedMessages.clear();
        }
    }
}
