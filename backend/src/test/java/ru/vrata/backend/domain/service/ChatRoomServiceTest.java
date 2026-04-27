package ru.vrata.backend.domain.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import ru.vrata.backend.domain.exception.RoomNotFoundException;
import ru.vrata.backend.domain.repository.ChatRoomRepository;
import ru.vrata.backend.domain.repository.inmemory.InMemoryChatRoomRepository;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;

class ChatRoomServiceTest {
    private ChatRoomService chatRoomService;
    private InMemoryChatRoomRepository chatRoomRepository;
    private CryptoIdGenerator cryptoIdGenerator;
    private RoomTopicManager roomTopicManager;

    @BeforeEach
    void setUp() {
        chatRoomRepository = new InMemoryChatRoomRepository();
        cryptoIdGenerator = Mockito.mock(CryptoIdGenerator.class);
        roomTopicManager = Mockito.mock(RoomTopicManager.class);

        when(cryptoIdGenerator.nextPositiveLong())
                .thenReturn(1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L, 9L, 10L);

        chatRoomService = new ChatRoomService(chatRoomRepository, cryptoIdGenerator, roomTopicManager);
    }

    @Test
    void createRoomShouldAutoJoinCreator() {
        var room = chatRoomService.createRoom(10L, "Main room");

        assertTrue(chatRoomRepository.isUserInRoom(room.id(), 10L));
        Mockito.verify(roomTopicManager).createRoomTopic(room.id());
    }

    @Test
    void createRoomShouldGenerateNameWhenBlank() {
        var room = chatRoomService.createRoom(10L, "   ");

        assertEquals("room-1", room.name());
    }

    @Test
    void joinRoomShouldWorkWithMixedCaseCode() {
        var room = chatRoomService.createRoom(1L, "Main room");

        var joined = chatRoomService.joinRoom(2L, room.inviteCode().toUpperCase());

        assertEquals(room.id(), joined.id());
        assertTrue(chatRoomRepository.isUserInRoom(room.id(), 2L));
    }

    @Test
    void joinRoomShouldBeIdempotentWhenAlreadyMember() {
        var room = chatRoomService.createRoom(1L, "Main room");

        var joined = chatRoomService.joinRoom(1L, room.inviteCode());

        assertEquals(room.id(), joined.id());
        assertTrue(chatRoomRepository.isUserInRoom(room.id(), 1L));
    }

    @Test
    void joinRoomShouldSwitchFromAnotherRoomAndDeleteOldRoomIfEmpty() {
        var targetRoom = chatRoomService.createRoom(1L, "Target room");
        var oldRoom = chatRoomService.createRoom(2L, "Old room");

        chatRoomService.joinRoom(2L, targetRoom.inviteCode());

        assertTrue(chatRoomRepository.isUserInRoom(targetRoom.id(), 2L));
        assertTrue(chatRoomRepository.findById(oldRoom.id()).isEmpty());
    }

    @Test
    void leaveRoomShouldDeleteRoomWhenLastMemberLeaves() {
        var room = chatRoomService.createRoom(1L, "Solo room");

        var result = chatRoomService.leaveRoom(1L);

        assertEquals(room.id(), result.leftRoomId());
        assertTrue(result.roomDeleted());
        assertTrue(chatRoomRepository.findById(room.id()).isEmpty());
        Mockito.verify(roomTopicManager).deleteRoomTopic(room.id());
    }

    @Test
    void leaveRoomShouldNotDeleteRoomWhenMembersRemain() {
        var room = chatRoomService.createRoom(1L, "Team room");
        chatRoomService.joinRoom(2L, room.inviteCode());

        var result = chatRoomService.leaveRoom(1L);

        assertEquals(room.id(), result.leftRoomId());
        assertFalse(result.roomDeleted());
        assertTrue(chatRoomRepository.findById(room.id()).isPresent());
        assertTrue(chatRoomRepository.isUserInRoom(room.id(), 2L));
        Mockito.verify(roomTopicManager, Mockito.never()).deleteRoomTopic(room.id());
    }

    @Test
    void leaveRoomShouldBeIdempotentWhenUserIsNotInRoom() {
        var result = chatRoomService.leaveRoom(999L);

        assertNull(result.leftRoomId());
        assertFalse(result.roomDeleted());
    }

    @Test
    void joinRoomShouldThrowWhenInviteCodeNotFound() {
        assertThrows(RoomNotFoundException.class, () -> chatRoomService.joinRoom(1L, "abcdef"));
    }

    @Test
    void createRoomShouldGenerateSixLetterInviteCode() {
        var room = chatRoomService.createRoom(10L, "Main room");

        assertNotNull(room.inviteCode());
        assertEquals(6, room.inviteCode().length());
        assertTrue(room.inviteCode().chars().allMatch(ch -> ch >= 'a' && ch <= 'z'));
    }

    @Test
    void createRoomShouldDeleteTopicWhenRepositoryCreateFails() {
        ChatRoomRepository repository = Mockito.mock(ChatRoomRepository.class);
        RoomTopicManager topicManager = Mockito.mock(RoomTopicManager.class);
        CryptoIdGenerator idGenerator = Mockito.mock(CryptoIdGenerator.class);

        when(idGenerator.nextPositiveLong()).thenReturn(100L);
        when(repository.findById(anyLong())).thenReturn(java.util.Optional.empty());
        doThrow(new RuntimeException("mongo down")).when(repository).create(any());

        ChatRoomService service = new ChatRoomService(repository, idGenerator, topicManager);

        assertThrows(RuntimeException.class, () -> service.createRoom(1L, "Main room"));
        Mockito.verify(topicManager).createRoomTopic(100L);
        Mockito.verify(topicManager).deleteRoomTopic(100L);
    }
}
