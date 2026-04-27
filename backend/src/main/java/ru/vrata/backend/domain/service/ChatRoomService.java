package ru.vrata.backend.domain.service;

import org.springframework.stereotype.Service;
import ru.vrata.backend.domain.exception.RoomNotFoundException;
import ru.vrata.backend.domain.model.ChatRoom;
import ru.vrata.backend.domain.repository.ChatRoomRepository;

import java.util.concurrent.ThreadLocalRandom;

@Service
public class ChatRoomService {
    private final ChatRoomRepository chatRoomRepository;
    private final CryptoIdGenerator cryptoIdGenerator;
    private final RoomTopicManager roomTopicManager;
    private static final int INVITE_CODE_LENGTH = 6;

    public ChatRoomService(ChatRoomRepository chatRoomRepository,
                           CryptoIdGenerator cryptoIdGenerator,
                           RoomTopicManager roomTopicManager) {
        this.chatRoomRepository = chatRoomRepository;
        this.cryptoIdGenerator = cryptoIdGenerator;
        this.roomTopicManager = roomTopicManager;
    }

    public ChatRoom createRoom(Long userId, String roomName) {
        validateUserId(userId);
        Long roomId = generateUniqueRoomId();
        String normalizedName = normalizeOrGenerateRoomName(roomName, roomId);
        ChatRoom room = new ChatRoom(roomId, normalizedName, generateUniqueInviteCode());

        chatRoomRepository.create(room);
        leaveRoom(userId);
        chatRoomRepository.addMember(room.id(), userId);
        return room;
    }

    public ChatRoom joinRoom(Long userId, String inviteCode) {
        validateUserId(userId);
        ChatRoom room = chatRoomRepository.findByInviteCode(inviteCode)
                .orElseThrow(() -> new RoomNotFoundException(inviteCode));

        if (chatRoomRepository.isUserInRoom(room.id(), userId)) {
            return room;
        }

        leaveRoom(userId);
        chatRoomRepository.addMember(room.id(), userId);
        return room;
    }

    public LeaveRoomResult leaveRoom(Long userId) {
        validateUserId(userId);

        var currentRoom = chatRoomRepository.findByUserId(userId);
        if (currentRoom.isEmpty()) {
            return new LeaveRoomResult(null, false);
        }

        Long roomId = currentRoom.get().id();
        chatRoomRepository.removeMember(roomId, userId);

        boolean roomDeleted = false;
        if (!chatRoomRepository.hasMembers(roomId)) {
            chatRoomRepository.deleteRoom(roomId);
            roomTopicManager.deleteRoomTopic(roomId);
            roomDeleted = true;
        }

        return new LeaveRoomResult(roomId, roomDeleted);
    }

    private long generateUniqueRoomId() {
        long id = cryptoIdGenerator.nextPositiveLong();
        while (chatRoomRepository.findById(id).isPresent()) {
            id = cryptoIdGenerator.nextPositiveLong();
        }
        return id;
    }

    private String generateUniqueInviteCode() {
        String code = randomInviteCode();

        while (chatRoomRepository.findByInviteCode(code).isPresent()) {
            code = randomInviteCode();
        }
        return code;
    }

    private String randomInviteCode() {
        StringBuilder code = new StringBuilder(INVITE_CODE_LENGTH);
        for (int i = 0; i < INVITE_CODE_LENGTH; i++) {
            code.append((char) ('a' + ThreadLocalRandom.current().nextInt(26)));
        }
        return code.toString();
    }

    private String normalizeOrGenerateRoomName(String roomName, Long roomId) {
        if (roomName == null || roomName.isBlank()) {
            return "room-%d".formatted(roomId);
        }
        return ChatRoom.normalizeName(roomName);
    }

    private void validateUserId(Long userId) {
        if (userId == null || userId <= 0) {
            throw new IllegalArgumentException("user id must be positive");
        }
    }

    public record LeaveRoomResult(Long leftRoomId, boolean roomDeleted) {
    }
}
