package ru.vrata.backend.api.message;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.validation.beanvalidation.LocalValidatorFactoryBean;
import ru.vrata.backend.api.common.GlobalExceptionHandler;
import ru.vrata.backend.domain.model.Message;
import ru.vrata.backend.domain.service.MessageService;

import java.util.List;
import java.util.UUID;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class MessageControllerTest {

    private MessageService messageService;
    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        messageService = mock(MessageService.class);
        MessageController controller = new MessageController(messageService);
        LocalValidatorFactoryBean validator = new LocalValidatorFactoryBean();
        validator.afterPropertiesSet();

        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .setValidator(validator)
                .build();
    }

    @Test
    void sendShouldReturnAccepted() throws Exception {
        mockMvc.perform(post("/api/v1/messages")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "roomId": 1,
                                  "userId": 42,
                                  "username": "rolan",
                                  "content": "hello world"
                                }
                                """))
                .andExpect(status().isAccepted());

        verify(messageService).sendMessage(1L, 42L, "rolan", "hello world");
    }

    @Test
    void sendShouldReturnBadRequestForInvalidPayload() throws Exception {
        mockMvc.perform(post("/api/v1/messages")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "roomId": 0,
                                  "userId": 42,
                                  "username": "ro",
                                  "content": ""
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
    }

    @Test
    void getRoomMessagesShouldReturnMessages() throws Exception {
        UUID firstId = UUID.randomUUID();
        UUID secondId = UUID.randomUUID();
        when(messageService.getMessagesForRoom(7L, 42L)).thenReturn(List.of(
                new Message(firstId, 7L, 42L, "rolan", "hello"),
                new Message(secondId, 7L, 99L, "teammate", "hi")
        ));

        mockMvc.perform(get("/api/v1/rooms/7/messages")
                        .queryParam("userId", "42"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].id").value(firstId.toString()))
                .andExpect(jsonPath("$[0].roomId").value(7))
                .andExpect(jsonPath("$[0].username").value("rolan"))
                .andExpect(jsonPath("$[1].id").value(secondId.toString()))
                .andExpect(jsonPath("$[1].username").value("teammate"));
    }

    @Test
    void getRoomMessagesShouldPassRoomAndUserToService() throws Exception {
        when(messageService.getMessagesForRoom(7L, 42L)).thenReturn(List.of());

        mockMvc.perform(get("/api/v1/rooms/7/messages")
                        .queryParam("userId", "42"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));

        verify(messageService).getMessagesForRoom(7L, 42L);
    }
}
