package ru.vrata.backend.api.room;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.validation.beanvalidation.LocalValidatorFactoryBean;
import ru.vrata.backend.api.common.GlobalExceptionHandler;
import ru.vrata.backend.domain.exception.RoomNotFoundException;
import ru.vrata.backend.domain.model.ChatRoom;
import ru.vrata.backend.domain.service.ChatRoomService;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class RoomControllerTest {
    private ChatRoomService chatRoomService;
    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        chatRoomService = mock(ChatRoomService.class);
        RoomController controller = new RoomController(chatRoomService);
        LocalValidatorFactoryBean validator = new LocalValidatorFactoryBean();
        validator.afterPropertiesSet();
        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .setValidator(validator)
                .build();
    }

    @Test
    void createShouldReturnCreatedRoom() throws Exception {
        ChatRoom room = new ChatRoom(7L, "Main room", "abcdef");
        when(chatRoomService.createRoom(42L, "Main room")).thenReturn(room);

        mockMvc.perform(post("/api/v1/rooms")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "userId": 42,
                                  "name": "Main room"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(7))
                .andExpect(jsonPath("$.name").value("Main room"))
                .andExpect(jsonPath("$.inviteCode").value("abcdef"));
    }

    @Test
    void joinShouldReturnRoom() throws Exception {
        ChatRoom room = new ChatRoom(7L, "Main room", "abcdef");
        when(chatRoomService.joinRoom(42L, "AbCdEf")).thenReturn(room);

        mockMvc.perform(post("/api/v1/rooms/join")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "userId": 42,
                                  "inviteCode": "AbCdEf"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(7))
                .andExpect(jsonPath("$.inviteCode").value("abcdef"));
    }

    @Test
    void leaveShouldReturnLeaveResult() throws Exception {
        when(chatRoomService.leaveRoom(42L))
                .thenReturn(new ChatRoomService.LeaveRoomResult(7L, true));

        mockMvc.perform(post("/api/v1/rooms/leave")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "userId": 42
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.leftRoomId").value(7))
                .andExpect(jsonPath("$.roomDeleted").value(true));
    }

    @Test
    void joinShouldReturnNotFoundWhenRoomMissing() throws Exception {
        when(chatRoomService.joinRoom(42L, "abcdef"))
                .thenThrow(new RoomNotFoundException("abcdef"));

        mockMvc.perform(post("/api/v1/rooms/join")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "userId": 42,
                                  "inviteCode": "abcdef"
                                }
                                """))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("ROOM_NOT_FOUND"));
    }

    @Test
    void createShouldReturnBadRequestForInvalidPayload() throws Exception {
        mockMvc.perform(post("/api/v1/rooms")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "userId": 0,
                                  "name": "Main room"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
    }

    @Test
    void joinShouldReturnBadRequestForInvalidInviteCode() throws Exception {
        mockMvc.perform(post("/api/v1/rooms/join")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "userId": 42,
                                  "inviteCode": "abc12x"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
    }
}
