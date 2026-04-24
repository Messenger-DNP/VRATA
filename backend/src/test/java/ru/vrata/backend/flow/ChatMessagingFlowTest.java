package ru.vrata.backend.flow;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import ru.vrata.backend.domain.service.KafkaMessageDeliveryService;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;
import ru.vrata.backend.infrastructure.kafka.producer.KafkaProducer;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = {
        "spring.docker.compose.enabled=false",
        "spring.kafka.listener.auto-startup=false",
        "app.mongo.migrations.enabled=false"
})
class ChatMessagingFlowTest {

    private static final Pattern NUMBER_PATTERN_TEMPLATE = Pattern.compile("\"%s\"\\s*:\\s*(\\d+)");
    private static final Pattern STRING_PATTERN_TEMPLATE = Pattern.compile("\"%s\"\\s*:\\s*\"([^\"]+)\"");

    @Autowired
    private WebApplicationContext webApplicationContext;

    @Autowired
    private KafkaMessageDeliveryService kafkaMessageDeliveryService;

    @Autowired
    private InMemoryKafkaOutbox inMemoryKafkaOutbox;

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(webApplicationContext).build();
        inMemoryKafkaOutbox.clear();
    }

    @Test
    void shouldRegisterTwoUsersCreateRoomSendAndReceiveMessages() throws Exception {
        long firstUserId = register("alice", "StrongPass123");
        long secondUserId = register("bobby", "StrongPass123");

        RoomInfo room = createRoom(firstUserId, "Main room");
        joinRoom(secondUserId, room.inviteCode());

        sendMessage(room.id(), firstUserId, "alice", "Hello from Alice");
        sendMessage(room.id(), secondUserId, "bobby", "Hello from Bob");

        deliverProducedMessages();

        assertUserRoomMessages(firstUserId, room.id());
        assertUserRoomMessages(secondUserId, room.id());
    }

    private long register(String username, String password) throws Exception {
        String body = """
                {
                  "username": "%s",
                  "password": "%s"
                }
                """.formatted(username, password);

        String response = mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();

        return extractLongField(response, "userId");
    }

    private RoomInfo createRoom(long userId, String name) throws Exception {
        String body = """
                {
                  "userId": %d,
                  "name": "%s"
                }
                """.formatted(userId, name);

        String response = mockMvc.perform(post("/api/v1/rooms")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();

        long roomId = extractLongField(response, "id");
        String inviteCode = extractStringField(response, "inviteCode");
        return new RoomInfo(roomId, inviteCode);
    }

    private void joinRoom(long userId, String inviteCode) throws Exception {
        String body = """
                {
                  "userId": %d,
                  "inviteCode": "%s"
                }
                """.formatted(userId, inviteCode);

        mockMvc.perform(post("/api/v1/rooms/join")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk());
    }

    private void sendMessage(long roomId, long userId, String username, String content) throws Exception {
        String body = """
                {
                  "roomId": %d,
                  "userId": %d,
                  "username": "%s",
                  "content": "%s"
                }
                """.formatted(roomId, userId, username, content);

        mockMvc.perform(post("/api/v1/messages")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isAccepted());
    }

    private void deliverProducedMessages() {
        List<KafkaMessage> producedMessages = inMemoryKafkaOutbox.drain();
        assertThat(producedMessages).hasSize(2);

        for (KafkaMessage message : producedMessages) {
            kafkaMessageDeliveryService.deliver(message);
        }
    }

    private void assertUserRoomMessages(long userId, long roomId) throws Exception {
        mockMvc.perform(get("/api/v1/rooms/{roomId}/messages", roomId)
                        .queryParam("userId", String.valueOf(userId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].roomId").value(roomId))
                .andExpect(jsonPath("$[1].roomId").value(roomId))
                .andExpect(jsonPath("$[0].content").value("Hello from Alice"))
                .andExpect(jsonPath("$[1].content").value("Hello from Bob"));
    }

    private long extractLongField(String json, String fieldName) {
        Pattern pattern = Pattern.compile(NUMBER_PATTERN_TEMPLATE.pattern().formatted(fieldName));
        Matcher matcher = pattern.matcher(json);
        if (!matcher.find()) {
            throw new IllegalStateException("Cannot find numeric field: " + fieldName);
        }
        return Long.parseLong(matcher.group(1));
    }

    private String extractStringField(String json, String fieldName) {
        Pattern pattern = Pattern.compile(STRING_PATTERN_TEMPLATE.pattern().formatted(fieldName));
        Matcher matcher = pattern.matcher(json);
        if (!matcher.find()) {
            throw new IllegalStateException("Cannot find string field: " + fieldName);
        }
        return matcher.group(1);
    }

    record RoomInfo(long id, String inviteCode) {
    }

    @TestConfiguration
    static class FlowTestConfig {
        @Bean
        InMemoryKafkaOutbox inMemoryKafkaOutbox() {
            return new InMemoryKafkaOutbox();
        }

        @Bean
        @Primary
        KafkaProducer kafkaProducer(InMemoryKafkaOutbox outbox) {
            return new KafkaProducer(null) {
                @Override
                public void produce(KafkaMessage message) {
                    outbox.add(message);
                }
            };
        }
    }

    static class InMemoryKafkaOutbox {
        private final List<KafkaMessage> producedMessages = new ArrayList<>();

        synchronized void add(KafkaMessage message) {
            producedMessages.add(message);
        }

        synchronized List<KafkaMessage> drain() {
            List<KafkaMessage> snapshot = List.copyOf(producedMessages);
            producedMessages.clear();
            return snapshot;
        }

        synchronized void clear() {
            producedMessages.clear();
        }
    }
}
